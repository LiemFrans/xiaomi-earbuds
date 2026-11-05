# QA Report — Xiaomi REDMI Buds 8 Pro macOS Companion App

**Date:** 2026-11-05  
**Swift Version:** 6.3.3 (Swift Language Mode: 6.0)  
**Platform:** macOS 15+  
**Files Audited:** 62 source files, 2 test files  
**Build Status:** ✅ PASS (`swift build` — 0 errors, 0 warnings)  
**Test Status:** ❌ FAIL (`swift test` — compilation error)  
**Code Quality Score:** **C** (Significant architectural and safety issues)  
**Overall Readiness:** 🟡 **Needs Fixes** before production release

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Critical Issues](#critical-issues)
3. [High Severity Issues](#high-severity-issues)
4. [Medium Severity Issues](#medium-severity-issues)
5. [Low Severity Issues](#low-severity-issues)
6. [Test Results](#test-results)
7. [Module Integration Audit](#module-integration-audit)
8. [Files Audited — Clean](#files-audited--clean)
9. [Recommendations](#recommendations)

---

## Executive Summary

The app compiles and runs, but the audit reveals **fundamental architectural disconnects** between modules. Views were built independently from ViewModels and DesignSystem components, resulting in:

- All 6 page Views use **local `@State`** instead of injected ViewModels
- **Zero** DesignSystem components are used by any View (only in ComponentCatalog)
- **Zero** `@MainActor` annotations across the entire codebase despite 8 mutable `@unchecked Sendable` classes
- **4 different battery-color implementations** with inconsistent thresholds
- Tests fail to compile (wrong testing framework import)

The app displays a static UI with hardcoded mock data. No View communicates with the Bluetooth services layer through the ViewModels.

---

## Critical Issues

### C-1: Views Do Not Use Injected ViewModels
**Severity:** Critical | **Category:** Integration/Architecture  
**Files:** All 6 page views, 4 menu bar views

`XiaomiEarbudsApp.swift` creates and injects 6 ViewModels via `.environment()`:
```swift
.environment(deviceVM)
.environment(noiseControlVM)
.environment(audioVM)
// ... etc
```

**However, no View reads them.** Every page uses local `@State` with hardcoded defaults:

| View | Expected | Actual |
|------|----------|--------|
| `OverviewPage` | `@Environment(DeviceViewModel.self)` | `@State private var batteryLeft: Int = 85` |
| `AudioPage` | `@Environment(AudioViewModel.self)` | `@State private var audioCodec: AudioCodec = .ldac` |
| `NoiseControlPage` | `@Environment(NoiseControlViewModel.self)` | `@State private var ancMode: ANCMode = .noiseCancellation` |
| `GesturesPage` | `@Environment(GestureViewModel.self)` | 10 separate `@State` properties |
| `SpatialAudioPage` | `@Environment(SpatialAudioViewModel.self)` | `@State private var audioQuality: AudioQuality = ...` |
| `SettingsPage` | `@Environment(SettingsViewModel.self)` | `@State private var inEarDetectionEnabled: Bool = true` |
| `MenuBarPopoverView` | Environment VMs | 8+ local `@State` properties |

**Impact:** The entire MVVM architecture is broken. User interactions update only local state — nothing persists, syncs, or communicates with the Bluetooth layer. The app is essentially a static mockup.

### C-2: Zero `@MainActor` Isolation in Swift 6 Concurrency Mode
**Severity:** Critical | **Category:** Concurrency/Data Safety  
**Files:** All ViewModels, `EarbudDevice`, `AppDelegate`, `XiaomiEarbudsApp`

The project uses **Swift Language Mode 6.0** (`Package.swift`), which enforces strict concurrency. Yet:

- **8 classes** use `@unchecked Sendable` to silence the compiler: `AudioViewModel`, `DeviceViewModel`, `NoiseControlViewModel`, `SettingsViewModel`, `GestureViewModel`, `SpatialAudioViewModel`, `EarbudDevice`, `DeviceStore`
- **Zero** `@MainActor` annotations exist in the entire codebase
- All ViewModel properties are `var` (mutable) with no synchronization

`@unchecked Sendable` **bypasses** Swift 6's data-race safety checks. These classes are UI-bound observable objects that must only be mutated on the main thread. Without `@MainActor`, any `Task {}` or background call can mutate them concurrently, causing undefined behavior.

**Impact:** Potential data races at runtime; compiler safety guarantees nullified.

---

## High Severity Issues

### H-1: Duplicate Menu Bar Implementation
**Severity:** High | **Category:** Integration/App Lifecycle  
**Files:** `AppDelegate.swift`, `XiaomiEarbudsApp.swift`

Two independent menu bar implementations exist:

1. **AppDelegate** creates an `NSStatusItem` + `NSPopover` with `MenuBarPopoverView()` (no environment injection)
2. **XiaomiEarbudsApp** declares a `MenuBarExtra` scene with `MenuBarPopoverView()` (with environment VMs)

**Impact:** Potentially two menu bar icons at runtime. The AppDelegate popover lacks ViewModel environment objects, so it would crash or show disconnected state.

### H-2: DesignSystem Components Completely Unused
**Severity:** High | **Category:** Integration/Dead Code  
**Files:** 10 DesignSystem components

All 10 DesignSystem components are defined but **never referenced** by any View:

| Component | Purpose | Used By |
|-----------|---------|---------|
| `ANCModePicker` | ANC mode selector | ComponentCatalog only |
| `BatteryGaugeView` | Battery display | ComponentCatalog only |
| `CodecRadioGroup` | Codec selector | ComponentCatalog only |
| `ConnectionStatusDot` | Status indicator | ComponentCatalog only |
| `DepthSlider` | ANC depth slider | ComponentCatalog only |
| `DeviceHeaderView` | Device hero | ComponentCatalog only |
| `GesturePickerRow` | Gesture picker | ComponentCatalog only |
| `SectionCard` | Section wrapper | ComponentCatalog only |
| `SettingToggleRow` | Toggle row | ComponentCatalog only |
| `SoundModeRadioGroup` | Sound mode picker | ComponentCatalog only |

Views re-implement their own inline versions (e.g., `OverviewBatteryItem` in OverviewPage, `BatteryGaugeItem` in QuickBatteryView).

### H-3: Four Inconsistent Battery Color Implementations
**Severity:** High | **Category:** Integration/Consistency  

| Location | Red | Orange/Yellow | Green |
|----------|-----|---------------|-------|
| `Color.forBatteryLevel()` (Utility) | 0–9% | 10–19% orange, 20–49% yellow | 50%+ |
| `ColorTokens.batteryColor()` (DesignSystem) | ≤10% | 11–20% yellow | 21%+ |
| `OverviewBatteryItem` (OverviewPage) | 0–19% | 20–39% orange | 40%+ |
| `BatteryGaugeItem` (QuickBatteryView) | 0–19% | 20–39% orange | 40%+ |

A user could see different colors for the same battery level depending on which screen they're viewing.

### H-4: `DeviceStore` Uses `ObservableObject`/`@Published` Instead of `@Observable`
**Severity:** High | **Category:** Consistency/Integration  
**File:** `Services/Persistence/DeviceStore.swift`

All other observable types use Swift Observation (`@Observable`), but `DeviceStore` uses the older `ObservableObject`/`@Published` pattern. This creates inconsistency and means it cannot be injected via the same `.environment()` pattern used for ViewModels.

---

## Medium Severity Issues

### M-1: `AppDelegate` Missing `@MainActor`
**Severity:** Medium | **Category:** Concurrency  
**File:** `App/AppDelegate.swift`

`AppDelegate` mutates `NSStatusItem`, `NSPopover`, and `NSHostingController` (AppKit UI) without `@MainActor` isolation. Under Swift 6, these must run on the main thread.

### M-2: Force-Unwrapped URLs in SettingsPage
**Severity:** Medium | **Category:** Error Handling  
**File:** `Views/Pages/SettingsPage.swift` (lines 47, 61, 71)

```swift
URL(string: "https://www.mi.com/global/support")!
```

Three force-unwrapped URL initializers. While these specific strings are valid, force unwraps are a crash risk if URLs change. Use `guard let` or a compile-time constant.

### M-3: Implicitly Unwrapped Optionals in Bluetooth Managers
**Severity:** Medium | **Category:** Error Handling  
**File:** `Services/Bluetooth/BluetoothManager.swift` (lines 33–34), `BLEManager.swift` (line 11)

```swift
private var centralManager: CBCentralManager!
private var delegateHandler: CentralManagerDelegate!
```

Three implicitly unwrapped optionals (`!`) used for delegate/manager initialization patterns. If `init()` is called incorrectly, these crash at runtime.

### M-4: `SettingsPage` Does Not Use `SettingsViewModel`
**Severity:** Medium | **Category:** Integration  
**File:** `Views/Pages/SettingsPage.swift`

`SettingsPage` has local `@State` for `inEarDetectionEnabled`, `dualConnectionEnabled`, etc. Meanwhile, `SettingsViewModel` exposes the same toggles via `DeviceSettings`. The disconnect means Settings page changes are lost on navigation.

### M-5: `MenuBarPopoverView` Ignores Injected VMs
**Severity:** Medium | **Category:** Integration  
**File:** `Views/MenuBar/MenuBarPopoverView.swift`

Has 8 local `@State` properties mirroring `DeviceViewModel` and `NoiseControlViewModel` data. The `XiaomiEarbudsApp` injects `deviceVM` and `noiseControlVM` into the MenuBarExtra, but the view ignores them.

### M-6: `AppSettings` (`ObservableObject`) Is Never Used
**Severity:** Medium | **Category:** Dead Code  
**File:** `Services/Persistence/AppSettings.swift`

`AppSettings` defines comprehensive `@AppStorage` properties for persistence but is never instantiated or referenced by any View or ViewModel.

### M-7: `BluetoothManager`/`BLEManager`/`XiaomiProtocol` Never Connected to ViewModels
**Severity:** Medium | **Category:** Integration  
**Files:** Services layer, ViewModels layer

The Services layer (`BluetoothManager`, `BLEManager`, `ClassicBTManager`, `XiaomiProtocol`) provides complete BLE communication APIs. The ViewModels have methods like `connect()`, `disconnect()`, `refreshBattery()`. However, **no ViewModel holds a reference to any Service**. ViewModels use `Task.sleep()` to simulate operations:

```swift
// DeviceViewModel.connect():
try? await Task.sleep(for: .seconds(1.5))  // Simulated, no real BT
device.batteryInfo = .mock
```

### M-8: Test File Mixes Incompatible Testing Frameworks
**Severity:** Medium | **Category:** Testing  
**File:** `Tests/XiaomiEarbudsTests/ProtocolTests.swift`

Imports `Testing` (Swift Testing framework) but uses `XCTestCase` and `XCTAssert*` (XCTest framework). The `Testing` module is not available in SPM test targets by default, causing compilation failure.

### M-9: `receiveData()` Actor Isolation Issue in ClassicBTManager
**Severity:** Medium | **Category:** Concurrency  
**File:** `Services/Bluetooth/ClassicBTManager.swift` (line ~105)

```swift
func receiveData() -> AsyncStream<Data> {
    AsyncStream<Data> { continuation in
        self.receiveStreamContinuation = continuation  // Captures actor-isolated self
```

The `AsyncStream` initializer closure is `@Sendable` but captures `self` (an actor) and mutates `receiveStreamContinuation` synchronously. This may cause a compiler warning or error depending on exact Swift 6 strictness.

---

## Low Severity Issues

### L-1: `ComponentCatalog` Missing `#Preview` Macro
**Severity:** Low | **Category:** Dead Code  
**File:** `DesignSystem/Previews/ComponentCatalog.swift`

No `#Preview` declaration found — the catalog is not discoverable in Xcode previews.

### L-2: `Color.forBatteryLevel()` Likely Orphaned
**Severity:** Low | **Category:** Dead Code  
**File:** `Utilities/Extensions/Color+Battery.swift`

Only referenced by `BatteryInfo.batteryColor`, which itself is never called by any View (Views compute colors inline).

### L-3: Accessibility Gaps in Radio/Picker Groups
**Severity:** Low | **Category:** Accessibility  
**Files:** `CodecRadioGroup.swift`, `SoundModeRadioGroup.swift`

Individual radio options don't explicitly expose selected/unselected state beyond native Picker behavior. Verify VoiceOver announces selection correctly with `.radioGroup` style on macOS.

### L-4: Battery Colors Use Non-Semantic System Colors
**Severity:** Low | **Category:** Dark Mode / Accessibility  
**File:** `DesignSystem/Tokens/ColorTokens.swift` (lines 32–34)

`Color.green`, `Color.yellow`, `Color.red` are used directly. These are not semantic colors and may have insufficient contrast for some accessibility settings.

### L-5: Status Colors Are Non-Adaptive
**Severity:** Low | **Category:** Dark Mode  
**File:** `DesignSystem/Tokens/ColorTokens.swift` (lines 46–47)

`statusConnected = Color.green` and `statusDisconnected = Color(.systemGray)` — the green is not adaptive for color-blind users.

### L-6: `ProtocolTestFixtures.buildFrame` No Overflow Guard
**Severity:** Low | **Category:** Error Handling  
**File:** `Tests/XiaomiEarbudsTests/ProtocolTestFixtures.swift` (~line 112)

`payload.count` is cast to `UInt16` without overflow check. Payloads over 65,535 bytes would silently truncate.

### L-7: Test Coverage Gaps
**Severity:** Low | **Category:** Testing  
**File:** `Tests/XiaomiEarbudsTests/ProtocolTests.swift`

- No malformed-frame edge case tests (truncated, oversized, unknown opcodes)
- `validateFrame()` not directly tested against all malformed fixtures
- Event fixtures tested only for selected payload values
- No negative/boundary tests for battery levels, ANC depth values

---

## Test Results

### `swift test` Output

```
error: emit-module command failed with exit code 1
Tests/XiaomiEarbudsTests/ProtocolTests.swift:8:8: error: no such module 'Testing'
```

**Root Cause:** Test file imports `import Testing` (Swift Testing framework) but the SPM test target does not depend on this module. The test classes use `XCTestCase`/`XCTAssert*` from XCTest, not Swift Testing APIs.

**Fix:** Replace `import Testing` with `import XCTest`.

**Tests Run:** 0  
**Tests Passed:** 0  
**Tests Failed:** 0 (could not compile)

---

## Module Integration Audit

### Connection Matrix

| From → To | Models | Services | ViewModels | Views | DesignSystem | Utilities |
|-----------|:------:|:--------:|:----------:|:-----:|:------------:|:---------:|
| **Models** | — | ✅ Used | ✅ Used | ✅ Used | ✅ Used | ✅ Used |
| **Services** | ✅ References | — | ❌ Not connected | ❌ Not used | — | ✅ Used |
| **ViewModels** | ✅ References | ❌ No service refs | — | ❌ Not consumed | — | — |
| **Views** | ✅ References | — | ❌ Ignores VMs | — | ❌ Not used | — |
| **DesignSystem** | ✅ References | — | — | ❌ Not used | — | — |

### Key Disconnects

1. **Services ↔ ViewModels:** ViewModels don't hold references to any Service class. All ViewModel "operations" are simulated with `Task.sleep()`.
2. **ViewModels ↔ Views:** Views use local `@State` instead of `@Environment` ViewModels. The injected VMs go unused.
3. **DesignSystem ↔ Views:** Views build inline component equivalents instead of using the DesignSystem components.
4. **AppSettings ↔ Everything:** `AppSettings` is fully defined but never instantiated.

### Orphaned/Dead Code Files

| File | Status |
|------|--------|
| `Utilities/Extensions/Color+Battery.swift` | Likely dead — only ref is unused `BatteryInfo.batteryColor` |
| `Services/Persistence/AppSettings.swift` | Dead — never instantiated |
| `DesignSystem/Previews/ComponentCatalog.swift` | Dead — no `#Preview` macro |
| All 10 DesignSystem Components | Unused by Views (only in ComponentCatalog) |

---

## Files Audited — Clean

The following files passed all checks with no issues found:

- `Models/ANCMode.swift`
- `Models/AudioCodec.swift`
- `Models/AudioQuality.swift`
- `Models/BluetoothError.swift`
- `Models/GestureAction.swift`
- `Models/GestureConfig.swift`
- `Models/SampleRate.swift`
- `Models/SceneRendering.swift`
- `Models/SoundMode.swift`
- `Models/DeviceModels.swift`
- `Models/DeviceSettings.swift`
- `DesignSystem/Tokens/SpacingTokens.swift`
- `DesignSystem/Tokens/TypographyTokens.swift`
- `Utilities/Extensions/Data+Hex.swift`
- `Utilities/Logging/AppLogger.swift`
- `Services/Protocol/CommandBuilder.swift`
- `Services/Protocol/ProtocolConstants.swift`
- `Views/MainWindow/ContentRouter.swift`
- `Views/MainWindow/MainWindowView.swift`
- `Views/MainWindow/SidebarView.swift`
- `Views/Sheets/FindDeviceSheet.swift`
- `Views/Sheets/RenameSheet.swift`

---

## Recommendations

### Priority 1 — Critical (Must Fix)

1. **Wire Views to ViewModels:** Replace all local `@State` in page Views with `@Environment(XxxViewModel.self)` bindings. This is the single most impactful fix.
2. **Add `@MainActor` to all ViewModels and `EarbudDevice`:** Replace `@unchecked Sendable` with `@MainActor` on all 7 `@Observable` classes. This restores Swift 6 safety guarantees.
3. **Fix test compilation:** Replace `import Testing` with `import XCTest` in `ProtocolTests.swift`.

### Priority 2 — High

4. **Remove duplicate menu bar:** Remove the `AppDelegate.setupMenuBarItem()` code. The `MenuBarExtra` in `XiaomiEarbudsApp` is the correct SwiftUI approach.
5. **Use DesignSystem components in Views:** Replace inline battery items, pickers, and toggles with the existing DesignSystem components.
6. **Consolidate battery colors:** Keep only `ColorTokens.batteryColor(for:)` and delete the other 3 implementations.
7. **Migrate `DeviceStore` to `@Observable`:** Replace `ObservableObject`/`@Published` with `@Observable` for consistency.

### Priority 3 — Medium

8. **Connect ViewModels to Services:** Add `BluetoothManager`/`XiaomiProtocol` references to ViewModels so real BLE operations can occur.
9. **Integrate `AppSettings`:** Wire `AppSettings` into the app for persistence of user preferences.
10. **Remove force unwraps:** Replace `URL(string:)!` with safe alternatives.
11. **Add edge-case tests:** Cover malformed frames, boundary values, unknown opcodes.

### Priority 4 — Low

12. **Improve accessibility:** Add `accessibilityAdjustableAction` to sliders, verify VoiceOver on radio groups.
13. **Use adaptive colors for battery/status indicators.**
14. **Clean up dead code:** Remove `Color+Battery.swift`, unused `ComponentCatalog` (or add `#Preview`).

---

## Issue Summary

| Severity | Count |
|----------|------:|
| Critical | 2 |
| High | 4 |
| Medium | 9 |
| Low | 7 |
| **Total** | **22** |

---

*Report generated by QA Audit Agent — 2026-11-05*
