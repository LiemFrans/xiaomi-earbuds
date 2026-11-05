# Product Requirements Document — MVP (Phase 1)

## REDMI Buds 8 Pro — macOS Companion App

| Field | Value |
|-------|-------|
| **Document Version** | 1.0 |
| **Date** | 2026-11-05 |
| **Author** | Product Manager |
| **Status** | Draft |
| **Target Device** | Xiaomi REDMI Buds 8 Pro (Firmware 3.2.2.6) |
| **Target Platform** | macOS 15 Sequoia+ |
| **BT Address** | B8:53:84:6B:BD:88 |
| **Supported Protocols** | HFP, AVRCP, A2DP, ACL |
| **Audio Codecs** | LDAC (48.0 kHz default), AAC, SBC |

---

## 1. Product Vision

Deliver a **native macOS companion app** for the Xiaomi REDMI Buds 8 Pro that gives users quick, menu-bar-first access to device status and core noise-control settings — matching the most essential features of the official Android app while feeling completely at home on macOS.

### 1.1 Goals

| # | Goal | Success Metric |
|---|------|---------------|
| G1 | Real-time device status at a glance | Battery levels visible within 1 click from menu bar |
| G2 | Quick ANC control without leaving current workflow | ANC mode switch < 500 ms end-to-end latency |
| G3 | Native macOS experience (not a port) | 100% Apple HIG controls; zero custom/Android-style widgets |
| G4 | Accessibility from day one | Full VoiceOver + keyboard navigation on every control |
| G5 | Reliable Bluetooth connection | Auto-reconnect within 3 seconds of device appearing |

### 1.2 Non-Goals (Explicitly Out of MVP Scope)

| # | Feature | Reason | Target Phase |
|---|---------|--------|-------------|
| NG1 | Gesture customization (single/double/triple press, hold, swipe) | Requires full protocol reverse-engineering for 10 gesture slots | Phase 2 |
| NG2 | Custom 10-band EQ | Requires undocumented frequency band data format | Phase 2 |
| NG3 | Immersive / Dimensional Audio controls | Requires Xiaomi SDK or deep protocol work | Phase 2 |
| NG4 | Head tracking toggle | Requires IMU sensor data protocol; high risk | Phase 2 |
| NG5 | Ear tip fit test | Requires proprietary audio analysis | Phase 3 |
| NG6 | Firmware OTA updates | Requires firmware binary protocol; high risk | Phase 3 |
| NG7 | Find my earbuds (play sound) | Requires protocol command discovery | Phase 2 |
| NG8 | Device rename | Lower priority; requires protocol command | Phase 2 |
| NG9 | In-ear detection / Dual connection toggles | Requires additional protocol commands | Phase 2 |
| NG10 | Localization (i18n beyond English) | English only for MVP | Phase 3 |

---

## 2. Target Users

| Persona | Description |
|---------|-------------|
| **Mac Power User** | Uses REDMI Buds 8 Pro daily with a Mac; wants fast ANC toggling and battery monitoring without reaching for their phone |
| **Developer / Creative Professional** | Works in focused sessions; needs to switch between Noise Cancellation (deep work) and Transparency (conversation) quickly |
| **Casual Listener** | Wants to see battery status and know which audio codec is active; prefers a set-and-forget menu bar utility |

---

## 3. Technical Constraints

| Constraint | Detail |
|-----------|--------|
| **Minimum macOS** | macOS 15 Sequoia (required for latest NavigationSplitView, `.radioGroup`, `.symbolEffect`) |
| **UI Framework** | SwiftUI (pure; AppKit bridging only for `NSStatusItem` + `NSPopover`) |
| **Architecture** | MVVM with `@Observable` (Swift Observation, not Combine) |
| **Concurrency** | Swift 6 strict concurrency — `actor`-based Bluetooth managers, `async/await` |
| **Bluetooth** | CoreBluetooth (BLE) + IOBluetooth (Classic BT RFCOMM/L2CAP) |
| **App Lifecycle** | Menu bar utility — persists in menu bar; main window opens/closes independently |
| **Distribution** | Direct DMG + Apple notarization + Sparkle auto-update (no App Store) |
| **Entitlements** | `com.apple.security.device.bluetooth`, App Sandbox, Hardened Runtime |

---

## 4. UI Surfaces

### 4.1 Menu Bar Popover (Primary Surface — Quick Access)

| Property | Value |
|----------|-------|
| **Trigger** | Click `NSStatusItem` icon (SF Symbol: `headphones`) in macOS menu bar |
| **Size** | 320 × 480 pt (width × max height) |
| **Behavior** | Transient — closes on outside click or Esc |
| **Background** | `.ultraThinMaterial` (vibrancy) |
| **Content** | Device header, battery row, ANC picker, ANC depth slider, codec display, "Open Settings…" button |

### 4.2 Main Settings Window (Secondary Surface — Full Control)

| Property | Value |
|----------|-------|
| **Trigger** | "Open Settings…" button in popover, or ⌘, keyboard shortcut |
| **Layout** | `NavigationSplitView` — collapsible sidebar (200 pt default) + detail pane |
| **Min Size** | 680 × 500 pt |
| **Default Size** | 780 × 600 pt |
| **Max Size** | 1200 × 900 pt |
| **Window Style** | `.titleBar` with unified toolbar |
| **Title** | "REDMI Buds 8 Pro" (dynamic — uses actual device name) |
| **Sidebar Sections** | Overview • Noise Control • Audio • (future: Spatial Audio, Gestures, Settings) |
| **Close Behavior** | ⌘W hides window; app stays in menu bar. ⌘Q quits entirely. |

---

## 5. MVP Feature Specifications

---

### 5.1 F-001: Device Overview Display

**Priority:** P0 — Must Have  
**Owner:** Frontend Engineer + Lead Frontend Engineer  
**Surfaces:** Menu Bar Popover, Main Window (Overview Page)

#### 5.1.1 Description

Display the connected device's identity: device name ("REDMI Buds 8 Pro"), a device illustration/image, the Dolby Audio badge, and real-time battery levels for Left earbud, Right earbud, and Charging Case.

#### 5.1.2 User Story

> **As a** Mac user with REDMI Buds 8 Pro connected,  
> **I want to** see my earbuds' name, image, Dolby Audio badge, and battery levels at a glance,  
> **So that** I can quickly assess device identity and remaining charge without opening my phone.

#### 5.1.3 Acceptance Criteria

| # | Given | When | Then |
|---|-------|------|------|
| AC-1 | Earbuds are paired and connected via Bluetooth | The user clicks the menu bar icon | The popover displays "REDMI Buds 8 Pro" as the device name, the device image, and a "Dolby Audio" badge |
| AC-2 | Earbuds are connected and battery data is available | The popover is open | Three battery indicators are shown: Left (e.g., "100%"), Right (e.g., "100%"), Case (e.g., "1%") with corresponding progress bars |
| AC-3 | Battery level for Left earbud is ≤ 10% | The popover is open | The Left battery bar turns red and the percentage text shows the low value |
| AC-4 | Battery level for Left earbud is 11–20% | The popover is open | The Left battery bar turns yellow/orange as a warning |
| AC-5 | Battery level for Left earbud is > 20% | The popover is open | The Left battery bar is green |
| AC-6 | Battery data updates from the device | The popover is already open | The battery percentages and bars animate smoothly to the new values within 1 second |
| AC-7 | VoiceOver is active | The user navigates to the battery section | VoiceOver reads "Left earbud battery: 100 percent", "Right earbud battery: 100 percent", "Case battery: 1 percent" |
| AC-8 | Earbuds are not connected | The user clicks the menu bar icon | The popover shows a "Not Connected" state with a disabled/greyed-out device image and "—" for battery values |

#### 5.1.4 Edge Cases

| # | Scenario | Expected Behavior |
|---|----------|-------------------|
| E-1 | Only one earbud is in the case (other is in ear) | Show actual battery for each; the one in-case may report via case BLE |
| E-2 | Case battery is 0% but earbuds are charged | Show 0% for case with red bar; earbuds show their independent levels |
| E-3 | Bluetooth connection drops while popover is open | Switch to "Reconnecting…" state; grey out battery values; auto-retry |
| E-4 | Device reports battery > 100% (firmware bug) | Clamp display to 100% |
| E-5 | Battery data is unavailable (protocol not yet decoded) | Show "—" with a tooltip "Battery data unavailable" |
| E-6 | Device name contains special characters or is very long | Truncate with ellipsis at 30 characters in popover; show full name in main window |

#### 5.1.5 macOS-Specific Notes

| Aspect | Android App | macOS App |
|--------|-------------|-----------|
| **Layout** | Full-screen card with large hero image | Compact popover (320 pt wide); hero image smaller or icon-sized |
| **Battery bars** | Custom rounded bars with gradient | `ProgressView` with `.linear` style + semantic color coding |
| **Dolby badge** | Custom badge graphic overlay | SF Symbol or small asset with `.caption` text label |
| **Interaction** | Scroll to see more | No scroll needed — all info visible immediately |
| **Dark Mode** | Android Material You theming | macOS semantic colors (`Color(.controlBackgroundColor)`) |

#### 5.1.6 SwiftUI Components Used

- `DeviceHeaderView` — hero image + device name + Dolby badge
- `BatteryGaugeView` × 3 — `ProgressView(.linear)` with color coding
- `ConnectionStatusDot` — `.symbolEffect(.pulse)` animated indicator
- `Text` — device name with `.headline` font

---

### 5.2 F-002: ANC Mode Toggle (3-Mode Segmented Picker)

**Priority:** P0 — Must Have  
**Owner:** Frontend Engineer + Software Engineer (BT protocol)  
**Surfaces:** Menu Bar Popover, Main Window (Noise Control Page)

#### 5.2.1 Description

A segmented control allowing the user to switch between three Active Noise Cancellation modes: **Transparency**, **Noise Cancellation**, and **Off**. The currently active mode is visually highlighted. Switching sends a BLE command to the earbuds and confirms the state change via BLE notification.

#### 5.2.2 User Story

> **As a** user in a noisy environment,  
> **I want to** quickly switch my earbuds to Noise Cancellation mode from the menu bar,  
> **So that** I can block distractions without interrupting my workflow or reaching for my phone.

#### 5.2.3 Acceptance Criteria

| # | Given | When | Then |
|---|-------|------|------|
| AC-1 | Earbuds are connected and current ANC mode is "Off" | The user taps the "Noise Cancellation" segment | The segment highlights to "Noise Cancellation", a BLE write command is sent, and within 500 ms the device confirms the mode change |
| AC-2 | ANC mode is "Noise Cancellation" | The user taps "Transparency" | The segment changes to "Transparency", the command is sent, and the device confirms |
| AC-3 | ANC mode is "Transparency" | The user taps "Off" | The segment changes to "Off", the command is sent, and the device confirms |
| AC-4 | The device confirms a mode change via BLE notification | The ViewModel receives the ACK | The UI updates to reflect the confirmed mode (not optimistic — waits for device ACK) |
| AC-5 | The BLE write command fails or times out (> 2 seconds) | After the timeout | The UI reverts to the previous mode and shows a brief inline error: "Failed to switch mode" |
| AC-6 | VoiceOver is active | The user navigates to the ANC picker | VoiceOver reads: "Noise control: Noise Cancellation selected. Transparency, Noise Cancellation, Off." |
| AC-7 | Earbuds are disconnected | The user views the ANC picker | The picker is disabled (greyed out) with the last known mode shown |
| AC-8 | The app launches and connects | Connection is established | The app reads the current ANC mode from the device and sets the picker to match |

#### 5.2.4 Edge Cases

| # | Scenario | Expected Behavior |
|---|----------|-------------------|
| E-1 | User rapidly toggles between modes | Debounce: only send the final mode after 200 ms of no further changes |
| E-2 | ANC mode changed on Android phone while macOS app is connected | macOS app receives BLE notification and updates picker to match |
| E-3 | BLE write succeeds but no ACK within 2 seconds | Revert UI, show error, log warning |
| E-4 | Earbuds battery critically low (< 5%) | ANC toggle still works (device handles low-battery limitations) |
| E-5 | User switches mode via physical gesture on earbuds | macOS app receives BLE notification and updates picker |

#### 5.2.5 macOS-Specific Notes

| Aspect | Android App | macOS App |
|--------|-------------|-----------|
| **Control** | Custom 3-pill toggle with icons | `Picker` with `.segmented` style — native macOS segmented control |
| **Icons** | Custom icons for each mode | SF Symbols: `ear` (Transparency), `ear.trianglebadge.exclamationmark` (ANC), `circle.slash` (Off) |
| **Haptics** | Android haptic feedback | No haptic on macOS; rely on visual segment animation |
| **Layout** | Full-width horizontal strip | Fits within 320 pt popover width |
| **Animation** | Custom spring animation | `.animation(.easeInOut(duration: 0.2))` on segment highlight |

#### 5.2.6 SwiftUI Components Used

- `ANCModePicker` — `Picker(selection:) { }.pickerStyle(.segmented)`
- SF Symbols per segment: `Label("Transparency", systemImage: "ear")`, etc.

#### 5.2.7 BLE Protocol Interaction

```
┌──────────┐                    ┌────────────────────┐
│  macOS   │  BLE Write (ANC)   │  REDMI Buds 8 Pro  │
│   App    │ ──────────────────> │                    │
│          │                    │  (switches mode)   │
│          │  BLE Notify (ACK)  │                    │
│          │ <────────────────── │                    │
└──────────┘                    └────────────────────┘
```

- **Write Characteristic:** Xiaomi Custom Service → ANC Control Characteristic
- **Payload:** TBD via protocol reverse-engineering (expected: opcode + mode enum byte)
- **ACK:** Device notifies back with current confirmed state
- **Target Latency:** < 500 ms from write to ACK

---

### 5.3 F-003: Smart Noise Cancellation Toggle

**Priority:** P0 — Must Have  
**Owner:** Frontend Engineer + Software Engineer (BT protocol)  
**Surfaces:** Main Window (Noise Control Page), Menu Bar Popover (optional if space permits)

#### 5.3.1 Description

A toggle switch that enables or disables **Smart Noise Cancellation**. When enabled, the earbuds automatically adjust the ANC depth based on the ambient noise environment. This is independent of the ANC mode selection — it modifies the behavior within the "Noise Cancellation" mode.

#### 5.3.2 User Story

> **As a** user who moves between quiet and noisy environments throughout the day,  
> **I want to** enable Smart Noise Cancellation so my earbuds automatically adjust ANC depth,  
> **So that** I get optimal noise cancellation without manually adjusting the slider.

#### 5.3.3 Acceptance Criteria

| # | Given | When | Then |
|---|-------|------|------|
| AC-1 | Earbuds are connected and Smart ANC is off | The user toggles Smart ANC to on | A BLE command is sent; upon ACK the toggle animates to the "on" position |
| AC-2 | Smart ANC is on | The user toggles it off | A BLE command is sent; upon ACK the toggle animates to "off" |
| AC-3 | Smart ANC is on | The user views the ANC Depth slider | The ANC Depth slider is disabled (greyed out) with a hint: "Controlled automatically by Smart ANC" |
| AC-4 | Smart ANC is off | The user views the ANC Depth slider | The slider is enabled and interactive |
| AC-5 | ANC mode is set to "Off" or "Transparency" | The user views Smart ANC toggle | The toggle is disabled with hint: "Available in Noise Cancellation mode only" |
| AC-6 | ANC mode is "Noise Cancellation" and Smart ANC is on | The current ANC depth changes automatically (device adjusts) | If the depth value is readable, display the current adaptive depth (read-only) |
| AC-7 | VoiceOver is active | The user navigates to the Smart ANC toggle | VoiceOver reads: "Smart Noise Cancellation, off, toggle. When enabled, ANC depth adjusts automatically." |
| AC-8 | BLE command fails or times out | After timeout | Toggle reverts to previous state; brief inline error shown |

#### 5.3.4 Edge Cases

| # | Scenario | Expected Behavior |
|---|----------|-------------------|
| E-1 | User turns on Smart ANC while ANC Depth slider is mid-drag | Slider resets to auto-controlled state; any pending manual depth write is cancelled |
| E-2 | Smart ANC state changed via Android app | macOS app receives BLE notification and updates toggle |
| E-3 | Device firmware does not support Smart ANC | Hide the toggle entirely; degrade gracefully |
| E-4 | Connection drops while Smart ANC is being toggled | Revert to last confirmed state when reconnected |

#### 5.3.5 macOS-Specific Notes

| Aspect | Android App | macOS App |
|--------|-------------|-----------|
| **Control** | Android Material Switch | Native macOS `Toggle` with `.toggleStyle(.switch)` |
| **Description** | Subtitle text below toggle | `SettingToggleRow` — `Toggle` wrapping `VStack { title; subtitle.font(.caption).foregroundStyle(.secondary) }` |
| **State coupling** | Smart ANC disables depth slider | Same — but macOS uses `Toggle.disabled()` + `.help()` tooltip |
| **Placement** | Inline in noise control list | `Form > Section("Noise Control")` in the Noise Control Page |

#### 5.3.6 SwiftUI Components Used

- `SettingToggleRow` — `Toggle` with title "Smart Noise Cancellation" and description subtitle
- `.disabled()` modifier when ANC mode ≠ Noise Cancellation
- `.help("Available in Noise Cancellation mode only")` tooltip on disabled state

---

### 5.4 F-004: ANC Depth Slider (Light ↔ Deep)

**Priority:** P1 — Should Have  
**Owner:** Frontend Engineer + Software Engineer (BT protocol)  
**Surfaces:** Menu Bar Popover, Main Window (Noise Control Page)

#### 5.4.1 Description

A horizontal slider allowing the user to manually adjust the Active Noise Cancellation depth from **Light** (minimal cancellation) to **Deep** (maximum cancellation). The slider sends real-time depth values to the earbuds as the user drags. It is disabled when Smart ANC is active.

#### 5.4.2 User Story

> **As a** user who prefers a specific level of noise cancellation,  
> **I want to** manually adjust how deeply my earbuds cancel noise using a slider,  
> **So that** I can find the right balance between silence and ambient awareness.

#### 5.4.3 Acceptance Criteria

| # | Given | When | Then |
|---|-------|------|------|
| AC-1 | ANC mode is "Noise Cancellation" and Smart ANC is off | The user drags the ANC depth slider toward "Deep" | The slider thumb moves, the value updates in real-time, and a BLE command with the new depth value is sent |
| AC-2 | The user stops dragging the slider | `onEditingChanged` fires with `false` | A final BLE write with the settled depth value is sent; this is the authoritative value |
| AC-3 | The slider is at the "Light" end | The display | The minimum label "Light" is visible on the left |
| AC-4 | The slider is at the "Deep" end | The display | The maximum label "Deep" is visible on the right |
| AC-5 | Smart ANC is enabled | The user views the slider | The slider is greyed out / disabled with tooltip: "Controlled automatically by Smart ANC" |
| AC-6 | ANC mode is "Off" or "Transparency" | The user views the slider | The slider is disabled with tooltip: "Available in Noise Cancellation mode only" |
| AC-7 | VoiceOver is active | The user navigates to the slider | VoiceOver reads: "ANC Depth, 70 percent, adjustable. Light to Deep." |
| AC-8 | App connects to earbuds | Connection established | Slider reads current depth value from device and positions thumb accordingly |
| AC-9 | User drags slider rapidly | During drag | Throttle BLE writes to max 1 write per 100 ms during active dragging; send final value on release |

#### 5.4.4 Edge Cases

| # | Scenario | Expected Behavior |
|---|----------|-------------------|
| E-1 | User drags slider extremely fast across entire range | Throttled writes; final settled value is sent on release |
| E-2 | BLE write for depth fails | Slider snaps back to last confirmed depth; error shown |
| E-3 | ANC depth changed by earbuds' physical gesture | macOS slider updates to reflect the new depth |
| E-4 | Depth value range from device differs from expected | Map device range to slider 0.0–1.0 range; store mapping |
| E-5 | Connection drops mid-drag | Slider becomes disabled; last dragged value is not persisted until reconnection confirms |

#### 5.4.5 macOS-Specific Notes

| Aspect | Android App | macOS App |
|--------|-------------|-----------|
| **Control** | Custom horizontal slider with circular thumb | Native macOS `Slider` with `minimumValueLabel` / `maximumValueLabel` |
| **Labels** | "Light" / "Deep" text at ends | `Slider(value:in:onEditingChanged:) { } minimumValueLabel: { Text("Light") } maximumValueLabel: { Text("Deep") }` |
| **Granularity** | Continuous | Continuous (0.0 – 1.0 mapped to device value range) |
| **Haptics** | None on Android slider | No haptic on macOS |
| **Keyboard** | Not keyboard-accessible on Android | Arrow keys adjust slider when focused (native macOS behavior) |

#### 5.4.6 SwiftUI Components Used

- `DepthSlider` — custom wrapper around `Slider`
- `.disabled()` when Smart ANC is on or ANC mode ≠ NC
- `.help()` tooltip for disabled states
- `.accessibilityValue()` for current percentage

---

### 5.5 F-005: Audio Codec Display

**Priority:** P1 — Should Have  
**Owner:** Frontend Engineer + Software Engineer (BT protocol)  
**Surfaces:** Menu Bar Popover, Main Window (Overview Page or Audio section)

#### 5.5.1 Description

Display the currently active audio codec (LDAC, AAC, or SBC) as a **read-only** informational label. In the MVP, codec switching is not supported — the display reflects whatever codec the system has negotiated. This gives users visibility into their audio quality.

#### 5.5.2 User Story

> **As a** music-conscious user,  
> **I want to** see which audio codec my earbuds are currently using,  
> **So that** I know whether I'm getting LDAC high-quality audio or a lower-quality fallback.

#### 5.5.3 Acceptance Criteria

| # | Given | When | Then |
|---|-------|------|------|
| AC-1 | Earbuds are connected with LDAC codec active | The user opens the popover | A label displays "LDAC" with a subtitle "High quality (48.0 kHz)" |
| AC-2 | Earbuds are connected with AAC codec active | The user opens the popover | A label displays "AAC" with a subtitle "High quality" |
| AC-3 | Earbuds are connected with SBC codec active | The user opens the popover | A label displays "SBC" with a subtitle "Standard quality" |
| AC-4 | The codec changes (e.g., system falls back from LDAC to AAC) | While the popover is open | The codec label updates to reflect the new codec within 2 seconds |
| AC-5 | Earbuds are disconnected | The user views the codec display | Shows "—" or "Not connected" |
| AC-6 | VoiceOver is active | The user navigates to the codec display | VoiceOver reads: "Audio codec: LDAC, High quality, 48 kilohertz" |
| AC-7 | Codec information is not available from the device | The user views the display | Shows "Unknown" with tooltip "Codec information unavailable" |

#### 5.5.4 Edge Cases

| # | Scenario | Expected Behavior |
|---|----------|-------------------|
| E-1 | LDAC is active but sample rate is unknown | Show "LDAC" without sample rate suffix |
| E-2 | Device reports an unrecognized codec identifier | Display "Unknown codec" and log the raw value for debugging |
| E-3 | Codec display area is too narrow for full text | Truncate subtitle; keep codec name visible |
| E-4 | macOS audio subsystem forces SBC during a call (HFP active) | Display "SBC" — reflect actual current codec, even if LDAC was previously active |

#### 5.5.5 macOS-Specific Notes

| Aspect | Android App | macOS App |
|--------|-------------|-----------|
| **Interaction** | Tappable — navigates to codec picker | **Read-only in MVP** — display only, no codec switching |
| **Layout** | Row with chevron (drill-down) | `LabeledContent("Audio Codec") { Text("LDAC").badge("48.0 kHz") }` — no chevron |
| **Future** | Full codec picker with radio buttons | Phase 2: `Picker(.radioGroup)` for codec selection |
| **Position in popover** | Part of audio settings drill-down | Inline in popover as informational row |
| **Position in main window** | Separate audio page | Overview Page → "Audio" section, or dedicated Audio Page |

#### 5.5.6 SwiftUI Components Used

- `LabeledContent` — codec name + quality subtitle
- `Text` with `.monospaced()` for codec name styling (optional)
- `.accessibilityElement(children: .combine)` to merge label + value for VoiceOver

---

### 5.6 F-006: Menu Bar App (Menu Bar Popover)

**Priority:** P0 — Must Have  
**Owner:** Frontend Engineer + Lead Frontend Engineer  
**Surfaces:** macOS Menu Bar (system-wide)

#### 5.6.1 Description

The app lives primarily in the macOS menu bar as a status item (headphones icon). Clicking the icon opens a popover that aggregates the most important quick-access features: device overview, battery, ANC mode toggle, ANC depth slider, audio codec display, and a button to open the full settings window. The popover is the primary interaction surface.

#### 5.6.2 User Story

> **As a** Mac user with REDMI Buds 8 Pro,  
> **I want to** access my earbuds' controls from the macOS menu bar,  
> **So that** I can check status and change settings without switching to a separate app window.

#### 5.6.3 Acceptance Criteria

| # | Given | When | Then |
|---|-------|------|------|
| AC-1 | The app is running | The user looks at the macOS menu bar | A headphones icon (`headphones` SF Symbol) is visible in the right-hand status area |
| AC-2 | Earbuds are connected | The user clicks the menu bar icon | A popover (320 × up to 480 pt) opens showing: device name, battery levels (L/R/Case), ANC mode picker, ANC depth slider, codec display, and "Open Settings…" button |
| AC-3 | The popover is open | The user clicks outside the popover or presses Esc | The popover closes |
| AC-4 | The popover is open | The user clicks the menu bar icon again | The popover closes (toggle behavior) |
| AC-5 | The popover is open | The user clicks "Open Settings…" | The main settings window opens and the popover closes |
| AC-6 | The app is launched at login (if configured) | macOS starts | The menu bar icon appears; no main window opens; the app is ready in the background |
| AC-7 | Earbuds are disconnected | The user clicks the menu bar icon | The popover opens with a "Not Connected" state: greyed icon, "—" battery values, disabled controls, and a "Searching…" or "Connect" prompt |
| AC-8 | ⌘Q is pressed with main window open | After the shortcut | The app quits entirely (menu bar icon disappears) |
| AC-9 | ⌘W is pressed with main window focused | After the shortcut | The main window closes but the app remains in the menu bar |
| AC-10 | VoiceOver is active | The user navigates to the menu bar icon | VoiceOver reads: "REDMI Buds 8 Pro, menu bar extra. Battery: Left 100%, Right 100%, Case 1%" |

#### 5.6.4 Popover Layout Specification

```
┌─────────────────────────────────────┐
│                                     │
│  🎧  REDMI Buds 8 Pro  ● Connected │  ← DeviceHeaderView
│                                     │
│  ┌──────────┬──────────┬──────────┐ │
│  │  ◀ L     │   ▶ R    │  ▣ Case │ │  ← QuickBatteryView
│  │  100%    │   100%   │    1%   │ │
│  │  ████▌   │   ████▌  │  █░░░░ │ │
│  └──────────┴──────────┴──────────┘ │
│                                     │
│  Noise Control                      │
│  ┌────────┬───────────┬───────────┐ │  ← QuickANCView
│  │ 🔊     │ 🔇 ANC    │ ⭕ Off   │ │
│  │ Trans. │  ●Active  │          │ │
│  └────────┴───────────┴───────────┘ │
│                                     │
│  ANC Depth                          │
│  Light ●━━━━━━━━━━━━━━━━○ Deep     │  ← DepthSlider
│                                     │
│  ─────────────────────────────────  │
│  Audio Codec               LDAC ▸  │  ← Codec display
│  ─────────────────────────────────  │
│                                     │
│         [ Open Settings… ]          │  ← Opens main window
│                                     │
└─────────────────────────────────────┘
```

#### 5.6.5 Edge Cases

| # | Scenario | Expected Behavior |
|---|----------|-------------------|
| E-1 | Multiple Bluetooth audio devices connected | Only show REDMI Buds 8 Pro if detected; ignore others |
| E-2 | macOS menu bar is crowded (many status items) | Icon is compact (single SF Symbol); no text in menu bar |
| E-3 | Display is in light mode / dark mode | SF Symbol and popover adapt automatically via semantic colors |
| E-4 | User has "Automatically hide and show the menu bar" enabled | Menu bar icon appears when menu bar is revealed — standard macOS behavior |
| E-5 | Popover opens near screen edge | `NSPopover` handles repositioning automatically |
| E-6 | User opens popover, switches to another app, clicks menu bar icon again | Popover toggles correctly regardless of app focus state |
| E-7 | App crashes and restarts | Menu bar icon reappears; auto-reconnect to earbuds |

#### 5.6.6 macOS-Specific Notes

| Aspect | Android App | macOS App |
|--------|-------------|-----------|
| **Entry point** | App icon in launcher → full-screen app | Menu bar icon → popover (320 × 480 pt) |
| **Always visible** | No — must open app | Yes — persistent menu bar icon |
| **Quick access** | Notification shade widget (optional) | Popover is the primary surface; always 1 click away |
| **Full settings** | Same app, just scroll down | Separate main window via "Open Settings…" |
| **Implementation** | Android Activity | `NSStatusItem` + `NSPopover` wrapping SwiftUI `MenuBarPopoverView` |
| **Background** | Solid/blurred background | `.ultraThinMaterial` — macOS vibrancy |

#### 5.6.7 SwiftUI Components Used

- `NSStatusItem` with `NSImage(systemSymbolName: "headphones")`
- `NSPopover` with `.contentSize(NSSize(width: 320, height: 480))`
- `MenuBarPopoverView` — SwiftUI root view inside the popover
- Contains: `DeviceHeaderView`, `QuickBatteryView`, `QuickANCView` (segmented picker + slider), `QuickActionsView` ("Open Settings…" button)

---

## 6. Cross-Cutting Requirements

### 6.1 Dark Mode + Light Mode

| # | Requirement |
|---|-------------|
| CR-1 | All UI adapts automatically to macOS appearance (Dark / Light) |
| CR-2 | No hardcoded colors — use only semantic colors from `ColorTokens.swift` |
| CR-3 | Battery bar colors (green, yellow, red) must be distinguishable in both modes |
| CR-4 | Device image / illustration adapts or is neutral for both modes |
| CR-5 | Test every screen in both modes before shipping |

### 6.2 VoiceOver Accessibility

| # | Requirement |
|---|-------------|
| CR-6 | Every interactive control has an `.accessibilityLabel()` |
| CR-7 | Every interactive control has an `.accessibilityHint()` where the action is non-obvious |
| CR-8 | Battery gauges combine label + value: "Left earbud battery: 100 percent" |
| CR-9 | ANC picker announces selected mode and available options |
| CR-10 | Slider announces current value as percentage and range ("Light to Deep") |
| CR-11 | Full keyboard Tab navigation through all controls |
| CR-12 | Esc key closes popover and sheets |
| CR-13 | Focus ring visible on all interactive elements |

### 6.3 Keyboard Navigation

| Shortcut | Action |
|----------|--------|
| Click menu bar icon | Toggle popover |
| Esc | Close popover / cancel sheet |
| Tab / Shift+Tab | Navigate between controls |
| Arrow keys | Adjust slider, navigate picker segments |
| Enter / Space | Activate button / toggle |
| ⌘W | Close main settings window |
| ⌘Q | Quit app |
| ⌘, | Open Settings window |

### 6.4 Performance Targets

| Metric | Target |
|--------|--------|
| App launch to menu bar icon | < 1 second |
| Popover open time | < 100 ms |
| BLE command round-trip (write → ACK) | < 500 ms |
| Memory usage (idle, menu bar) | < 30 MB |
| Memory usage (main window open) | < 50 MB |
| CPU usage (idle, menu bar) | < 1% |
| Battery level polling interval | 30 seconds (not continuous) |
| Auto-reconnect time | < 3 seconds after device appears |

### 6.5 Error Handling

| Scenario | User-Facing Behavior |
|----------|---------------------|
| Bluetooth is off on Mac | Popover shows: "Bluetooth is turned off. Open System Settings to enable Bluetooth." with button |
| Device not found / not paired | Popover shows: "REDMI Buds 8 Pro not found. Make sure your earbuds are charged and in pairing range." |
| BLE command timeout | Inline error text below the affected control: "Failed to update. Tap to retry." |
| BLE command rejected by device | Inline error: "Setting not supported by current firmware." |
| App loses BT connection | Status changes to "Reconnecting…"; auto-retry with exponential backoff (1s, 2s, 4s, 8s, max 30s) |
| Unexpected protocol response | Log to `os.Logger(subsystem:category:)` with `.error` level; UI shows "Unexpected response" |

---

## 7. Data Model (MVP)

```swift
// Core device state — @Observable for SwiftUI binding
@Observable
class EarbudDevice {
    var name: String = "REDMI Buds 8 Pro"
    var isConnected: Bool = false
    var connectionState: ConnectionState = .disconnected

    // Battery
    var batteryLeft: Int? = nil     // 0–100, nil if unknown
    var batteryRight: Int? = nil    // 0–100, nil if unknown
    var batteryCase: Int? = nil     // 0–100, nil if unknown

    // ANC
    var ancMode: ANCMode = .off
    var smartANCEnabled: Bool = false
    var ancDepth: Double = 0.5      // 0.0 (Light) – 1.0 (Deep)

    // Audio
    var activeCodec: AudioCodec = .unknown
    var codecSampleRate: String? = nil  // e.g., "48.0 kHz"

    // Firmware
    var firmwareVersion: String? = nil
}

enum ConnectionState { case disconnected, scanning, connecting, connected, reconnecting }
enum ANCMode: String, CaseIterable { case transparency, noiseCancellation, off }
enum AudioCodec: String { case ldac, aac, sbc, unknown }
```

---

## 8. Dependencies & Risks

### 8.1 Dependencies

| # | Dependency | Owner | Status | Impact if Delayed |
|---|-----------|-------|--------|-------------------|
| D-1 | BLE GATT service enumeration complete | Hardware Engineer | In Progress | Cannot implement any BLE commands |
| D-2 | ANC command protocol decoded | Hardware Engineer | Not Started | ANC toggle shows UI but sends no commands |
| D-3 | Battery BLE characteristic identified | Hardware Engineer | Not Started | Battery shows mock data |
| D-4 | Codec reporting mechanism identified | Hardware Engineer | Not Started | Codec display shows "Unknown" |
| D-5 | Design system components built | Lead Frontend Engineer | In Progress | Views use placeholder components |

### 8.2 Risks

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|-----------|
| R-1 | ANC protocol commands not decodable | Medium | High | Use mock data + UI complete; swap in real BLE when ready |
| R-2 | Battery reported via Classic BT only (not BLE) | Medium | Medium | Fall back to IOBluetooth for battery reads |
| R-3 | LDAC codec info not readable from macOS BT stack | High | Low | Show codec as "Unknown" until protocol provides it |
| R-4 | Smart ANC not a single BLE command | Low | Medium | May need compound command sequence; degrade to simple on/off |
| R-5 | macOS 15 SwiftUI regressions | Low | Low | Pin to Xcode 16 stable; report to Apple |

---

## 9. Release Criteria (MVP Definition of Done)

| # | Criterion | Verification |
|---|-----------|-------------|
| RC-1 | Menu bar icon appears on app launch | Manual test |
| RC-2 | Popover opens/closes on menu bar click | Manual test |
| RC-3 | Device name, image, Dolby badge displayed | Visual inspection |
| RC-4 | Battery levels (L/R/Case) display correctly | Compared with Android app |
| RC-5 | ANC mode switches between 3 modes | BLE confirmed or mock data |
| RC-6 | Smart ANC toggle works and disables depth slider | Functional test |
| RC-7 | ANC depth slider sends values and reflects device state | BLE confirmed or mock data |
| RC-8 | Audio codec displays correct current codec | Compared with Android app |
| RC-9 | Dark mode + Light mode — all screens correct | Visual inspection both modes |
| RC-10 | VoiceOver reads all controls correctly | VoiceOver manual test |
| RC-11 | Keyboard navigation works through all controls | Tab-through test |
| RC-12 | No crashes in 30-minute continuous use | Stability test |
| RC-13 | Memory < 50 MB with main window open | Activity Monitor check |
| RC-14 | ≥ 80% unit test coverage on ViewModels | Xcode coverage report |
| RC-15 | Notarized build runs on clean macOS 15 install | Clean-install test |

---

## 10. Appendix

### A. Feature-to-Surface Matrix

| Feature | Menu Bar Popover | Main Window — Overview | Main Window — Noise Control | Main Window — Audio |
|---------|:---:|:---:|:---:|:---:|
| F-001 Device Overview | ✅ (compact) | ✅ (full hero) | — | — |
| F-002 ANC Mode Toggle | ✅ | — | ✅ | — |
| F-003 Smart ANC Toggle | ⚠️ (if space) | — | ✅ | — |
| F-004 ANC Depth Slider | ✅ | — | ✅ | — |
| F-005 Codec Display | ✅ (label only) | ✅ (with detail) | — | ✅ (future full page) |
| F-006 Menu Bar App | ✅ (is the surface) | — | — | — |

### B. Android Screenshot → macOS Feature Mapping

| Android Screenshot | MVP Feature(s) Extracted |
|-------------------|--------------------------|
| Main dashboard (device, battery, ANC) | F-001 Device Overview, F-002 ANC Mode, F-004 Depth Slider |
| Smart noise control screen | F-003 Smart ANC Toggle |
| Audio settings (codec row) | F-005 Codec Display |
| *All screens* | F-006 Menu Bar App (aggregates top-level items into popover) |

### C. Glossary

| Term | Definition |
|------|-----------|
| **ANC** | Active Noise Cancellation — uses microphones to generate inverse sound waves |
| **BLE** | Bluetooth Low Energy — low-power wireless protocol |
| **GATT** | Generic Attribute Profile — BLE data hierarchy (services → characteristics) |
| **LDAC** | Sony's high-quality Bluetooth audio codec (up to 990 kbps) |
| **AAC** | Advanced Audio Coding — standard Bluetooth audio codec |
| **SBC** | Sub-Band Coding — baseline Bluetooth audio codec |
| **HFP** | Hands-Free Profile — Bluetooth profile for phone calls |
| **AVRCP** | Audio/Video Remote Control Profile — media playback control |
| **A2DP** | Advanced Audio Distribution Profile — stereo audio streaming |
| **ACK** | Acknowledgement — confirmation response from device |
| **HIG** | Human Interface Guidelines — Apple's design standards |

---

*End of document.*
