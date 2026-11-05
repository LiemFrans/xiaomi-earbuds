# UAT Test Plan — MVP (Phase 1)

## REDMI Buds 8 Pro — macOS Companion App

| Field | Value |
|-------|-------|
| **Document Version** | 1.0 |
| **Date** | 2026-11-05 |
| **Author** | Product Manager |
| **Status** | Draft |
| **Target Device** | Xiaomi REDMI Buds 8 Pro (Firmware 3.2.2.6) |
| **Target Platform** | macOS 15 Sequoia+ |
| **Test Environment** | Mac with Bluetooth, REDMI Buds 8 Pro paired |

---

## 1. Overview

This UAT test plan covers all MVP (Phase 1) features of the REDMI Buds 8 Pro macOS Companion App. Each scenario maps directly to a feature in the [PRD_MVP.md](./PRD_MVP.md) and validates user-facing behavior.

### 1.1 Test Scope

| In Scope | Out of Scope |
|----------|-------------|
| Device Overview display (F-001) | Gesture customization |
| ANC Mode Toggle (F-002) | Custom EQ / 10-band equalizer |
| Smart ANC Toggle (F-003) | Dimensional / Spatial Audio |
| ANC Depth Slider (F-004) | Head tracking |
| Audio Codec Display (F-005) | Firmware OTA update |
| Menu Bar App / Popover (F-006) | Find my earbuds |
| Dark Mode + Light Mode | Localization (non-English) |
| VoiceOver Accessibility | Ear tip fit test |
| Keyboard Navigation | Device rename |
| Error states & disconnection handling | Multi-device management |

### 1.2 Test Environment Requirements

| # | Requirement | Details |
|---|------------|---------|
| ENV-1 | **Mac hardware** | Any Mac running macOS 15 Sequoia or later |
| ENV-2 | **Bluetooth** | Built-in Bluetooth enabled and functional |
| ENV-3 | **REDMI Buds 8 Pro** | Paired to the test Mac via System Settings → Bluetooth |
| ENV-4 | **Earbud charge** | Left and Right earbuds charged (> 50%); Case charged (> 10%) |
| ENV-5 | **App installed** | REDMI Buds 8 Pro macOS companion app installed and running |
| ENV-6 | **Android phone (comparison)** | Xiaomi Earbuds Android app installed for reference values |
| ENV-7 | **VoiceOver** | Testable via System Settings → Accessibility → VoiceOver |
| ENV-8 | **Dark Mode toggle** | System Settings → Appearance → Dark / Light |

### 1.3 Pass/Fail Criteria

| Result | Definition |
|--------|-----------|
| **PASS** | The expected result is fully met. No visual, functional, or accessibility regressions. |
| **FAIL** | The expected result is not met, or a regression/crash occurs. |
| **BLOCKED** | Cannot execute due to missing dependency (e.g., BLE protocol not decoded). |
| **N/A** | Not applicable in the current test environment. |

### 1.4 Severity Levels

| Severity | Definition | Action |
|----------|-----------|--------|
| **S1 — Critical** | App crash, data loss, or complete feature failure | Must fix before release |
| **S2 — Major** | Feature partially broken; workaround exists | Must fix before release |
| **S3 — Minor** | Cosmetic issue or minor UX deviation | Fix if time permits |
| **S4 — Trivial** | Suggestion or polish item | Defer to next phase |

---

## 2. Test Scenarios

---

### 2.1 TS-001: Device Overview Display

**Feature:** F-001 — Device Overview  
**Priority:** P0

---

#### TC-001.1: Device Name and Image Display (Connected)

| Field | Value |
|-------|-------|
| **Pre-conditions** | REDMI Buds 8 Pro paired and connected; app running |
| **Steps** | 1. Click the headphones icon in the macOS menu bar |
|           | 2. Observe the device header area in the popover |
| **Expected Result** | Device name "REDMI Buds 8 Pro" is displayed. A device image/icon is shown. A "Dolby Audio" badge is visible near the device name. |
| **Pass Criteria** | Name matches paired device name; image renders correctly; Dolby badge present |

---

#### TC-001.2: Battery Levels Displayed Correctly

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; battery data available |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Observe the battery section |
|           | 3. Compare values with the Android Xiaomi Earbuds app |
| **Expected Result** | Three battery indicators shown: Left (e.g., "100%"), Right (e.g., "100%"), Case (e.g., "1%"). Each has a colored progress bar. Values match Android app within ±2%. |
| **Pass Criteria** | All three battery values visible and within ±2% of Android reference |

---

#### TC-001.3: Battery Color Coding

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected |
| **Steps** | 1. Open the popover |
|           | 2. Observe battery bar for a level > 20% → should be green |
|           | 3. If testable: deplete case to 11–20% → should be yellow/orange |
|           | 4. If testable: deplete case to ≤ 10% → should be red |
| **Expected Result** | Green for > 20%, yellow/orange for 11–20%, red for ≤ 10% |
| **Pass Criteria** | Colors match the specified thresholds |

---

#### TC-001.4: Battery Updates in Real Time

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; popover open |
| **Steps** | 1. Keep popover open |
|           | 2. Use earbuds for several minutes (play audio) to drain battery |
|           | 3. Observe battery values |
| **Expected Result** | Battery percentages update within 30 seconds of a change. Progress bars animate smoothly to new values. |
| **Pass Criteria** | Values update without manually closing/reopening popover |

---

#### TC-001.5: Disconnected State Display

| Field | Value |
|-------|-------|
| **Pre-conditions** | App running; earbuds NOT connected (powered off or out of range) |
| **Steps** | 1. Click menu bar icon |
|           | 2. Observe the popover |
| **Expected Result** | Device image is greyed out or dimmed. Battery values show "—" for all three. A "Not Connected" label or "Searching…" indicator is shown. ANC controls are disabled. |
| **Pass Criteria** | All disconnected-state indicators present; no crash |

---

#### TC-001.6: Device Overview in Main Window

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; main settings window open; "Overview" selected in sidebar |
| **Steps** | 1. Open the main settings window via "Open Settings…" |
|           | 2. Select "Overview" in the sidebar |
|           | 3. Observe the detail pane |
| **Expected Result** | Full-size device hero image, device name, Dolby Audio badge, and all three battery levels are displayed with larger components than the popover. |
| **Pass Criteria** | All elements render correctly in the larger layout |

---

### 2.2 TS-002: ANC Mode Toggle

**Feature:** F-002 — ANC Mode Toggle (3-Mode Segmented Picker)  
**Priority:** P0

---

#### TC-002.1: Switch to Noise Cancellation Mode

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; current ANC mode is "Off" or "Transparency" |
| **Steps** | 1. Open the menu bar popover |
|           | 2. In the "Noise Control" segmented picker, click "Noise Cancellation" (or the ANC segment with ear icon) |
| **Expected Result** | The "Noise Cancellation" segment highlights. A BLE command is sent. The earbuds switch to ANC mode (audible change). UI confirms within 500 ms. |
| **Pass Criteria** | Segment highlighted; earbuds audibly change mode; latency < 500 ms |

---

#### TC-002.2: Switch to Transparency Mode

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; current ANC mode is "Noise Cancellation" or "Off" |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Click the "Transparency" segment |
| **Expected Result** | "Transparency" segment highlights. Earbuds switch to transparency mode (ambient sounds become audible). |
| **Pass Criteria** | Mode changes audibly; segment highlighted |

---

#### TC-002.3: Switch to Off Mode

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; current ANC mode is "Noise Cancellation" or "Transparency" |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Click the "Off" segment |
| **Expected Result** | "Off" segment highlights. ANC and transparency are disabled. |
| **Pass Criteria** | Mode changes; no ANC or transparency active |

---

#### TC-002.4: ANC Mode Persists After Popover Close/Reopen

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected |
| **Steps** | 1. Open popover |
|           | 2. Switch ANC to "Noise Cancellation" |
|           | 3. Close the popover (click outside or press Esc) |
|           | 4. Reopen the popover |
| **Expected Result** | The "Noise Cancellation" segment is still highlighted. The earbuds are still in ANC mode. |
| **Pass Criteria** | State persists across popover close/reopen |

---

#### TC-002.5: ANC Toggle Disabled When Disconnected

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds NOT connected |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Observe the ANC segmented picker |
| **Expected Result** | The picker is disabled (greyed out). The last known mode may be shown but cannot be changed. Clicking has no effect. |
| **Pass Criteria** | Picker is visually disabled; no interaction possible; no crash |

---

#### TC-002.6: ANC Mode Sync from Physical Gesture

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; popover open |
| **Steps** | 1. Use the earbuds' physical gesture (press-and-hold) to cycle ANC mode |
|           | 2. Observe the ANC picker in the macOS popover |
| **Expected Result** | The macOS app receives a BLE notification and updates the segmented picker to reflect the new mode set by the physical gesture. |
| **Pass Criteria** | Picker auto-updates without user interaction on the Mac |

---

#### TC-002.7: Rapid ANC Toggling (Stress Test)

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Rapidly click between all three ANC segments 10 times in quick succession |
| **Expected Result** | No crash. No visual glitch. The final selected mode is correctly applied to the earbuds. Intermediate modes may be debounced. |
| **Pass Criteria** | App remains stable; final mode matches UI selection |

---

#### TC-002.8: ANC Mode in Main Window (Noise Control Page)

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; main window open; "Noise Control" selected in sidebar |
| **Steps** | 1. Switch ANC mode using the segmented picker in the Noise Control detail pane |
| **Expected Result** | Same behavior as popover: segment highlights, BLE command sent, mode changes. |
| **Pass Criteria** | Noise Control page ANC picker is functional and in sync with popover |

---

### 2.3 TS-003: Smart Noise Cancellation Toggle

**Feature:** F-003 — Smart ANC Toggle  
**Priority:** P0

---

#### TC-003.1: Enable Smart ANC

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; ANC mode is "Noise Cancellation"; Smart ANC is OFF |
| **Steps** | 1. Open the main settings window → Noise Control page |
|           | 2. Toggle "Smart Noise Cancellation" to ON |
| **Expected Result** | Toggle animates to ON. BLE command sent. Upon ACK, the ANC Depth slider becomes disabled (greyed out) with tooltip "Controlled automatically by Smart ANC". |
| **Pass Criteria** | Toggle ON; slider disabled; BLE confirmed |

---

#### TC-003.2: Disable Smart ANC

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; ANC mode is "Noise Cancellation"; Smart ANC is ON |
| **Steps** | 1. Open the Noise Control page |
|           | 2. Toggle "Smart Noise Cancellation" to OFF |
| **Expected Result** | Toggle animates to OFF. BLE command sent. ANC Depth slider becomes enabled and interactive. |
| **Pass Criteria** | Toggle OFF; slider re-enabled |

---

#### TC-003.3: Smart ANC Disabled When ANC Mode is Off

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; ANC mode is "Off" |
| **Steps** | 1. Open the Noise Control page |
|           | 2. Observe the Smart ANC toggle |
| **Expected Result** | The toggle is disabled (greyed out). A hint reads: "Available in Noise Cancellation mode only". |
| **Pass Criteria** | Toggle disabled with correct hint text |

---

#### TC-003.4: Smart ANC Disabled When ANC Mode is Transparency

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; ANC mode is "Transparency" |
| **Steps** | 1. Open the Noise Control page |
|           | 2. Observe the Smart ANC toggle |
| **Expected Result** | The toggle is disabled with hint: "Available in Noise Cancellation mode only". |
| **Pass Criteria** | Toggle disabled; correct hint |

---

#### TC-003.5: Smart ANC State Restores on Reconnection

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; Smart ANC toggled ON; ANC mode "Noise Cancellation" |
| **Steps** | 1. Disconnect earbuds (turn off or move out of range) |
|           | 2. Wait for "Reconnecting…" state |
|           | 3. Reconnect earbuds |
|           | 4. Open the Noise Control page |
| **Expected Result** | Smart ANC toggle reflects the device's current state (read from device on reconnect). |
| **Pass Criteria** | Toggle state matches device state after reconnection |

---

#### TC-003.6: Smart ANC Toggle Failure Handling

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; BLE write simulated to fail (or device unresponsive) |
| **Steps** | 1. Toggle Smart ANC |
|           | 2. BLE write fails/times out (> 2 seconds) |
| **Expected Result** | Toggle reverts to its previous state. An inline error message is shown briefly: "Failed to update. Tap to retry." |
| **Pass Criteria** | Toggle reverts; error message displayed; no crash |

---

### 2.4 TS-004: ANC Depth Slider

**Feature:** F-004 — ANC Depth Slider (Light ↔ Deep)  
**Priority:** P1

---

#### TC-004.1: Slider Adjusts ANC Depth

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; ANC mode is "Noise Cancellation"; Smart ANC is OFF |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Drag the ANC Depth slider from the current position toward "Deep" |
|           | 3. Release the slider |
| **Expected Result** | Slider thumb moves with the drag. On release, a BLE command with the final depth value is sent. The earbuds audibly adjust noise cancellation intensity. |
| **Pass Criteria** | Slider interactive; ANC depth audibly changes; BLE confirmed |

---

#### TC-004.2: Slider Labels Visible

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; ANC depth slider visible |
| **Steps** | 1. Observe the slider in the popover or Noise Control page |
| **Expected Result** | "Light" label visible on the left end. "Deep" label visible on the right end. |
| **Pass Criteria** | Both labels visible and correctly positioned |

---

#### TC-004.3: Slider Disabled When Smart ANC is On

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; ANC mode "Noise Cancellation"; Smart ANC ON |
| **Steps** | 1. Observe the ANC Depth slider |
|           | 2. Attempt to drag it |
| **Expected Result** | Slider is greyed out and non-interactive. Tooltip (on hover): "Controlled automatically by Smart ANC". |
| **Pass Criteria** | Slider disabled; tooltip present; no interaction possible |

---

#### TC-004.4: Slider Disabled When ANC Mode is Off or Transparency

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; ANC mode is "Off" or "Transparency" |
| **Steps** | 1. Observe the ANC Depth slider |
| **Expected Result** | Slider is disabled. Tooltip: "Available in Noise Cancellation mode only". |
| **Pass Criteria** | Slider disabled with correct tooltip |

---

#### TC-004.5: Slider Reads Initial Value from Device

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; device has a previously set ANC depth |
| **Steps** | 1. Open the popover |
|           | 2. Observe the slider position |
| **Expected Result** | Slider thumb is positioned to match the current ANC depth value read from the device. |
| **Pass Criteria** | Slider position reflects device state, not a default/reset value |

---

#### TC-004.6: Slider Keyboard Accessibility

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; ANC depth slider enabled |
| **Steps** | 1. Use Tab key to focus the slider |
|           | 2. Press Left/Right arrow keys |
| **Expected Result** | Slider value decreases (Left → toward Light) or increases (Right → toward Deep) in small increments. |
| **Pass Criteria** | Arrow keys adjust the slider; focus ring visible |

---

#### TC-004.7: Slider in Main Window (Noise Control Page)

| Field | Value |
|-------|-------|
| **Pre-conditions** | Main window open; Noise Control page selected; ANC "Noise Cancellation" active |
| **Steps** | 1. Drag the slider in the Noise Control detail pane |
| **Expected Result** | Same behavior as popover slider. Change is reflected in both popover and main window if both are visible. |
| **Pass Criteria** | Slider functional in main window; synced with popover |

---

### 2.5 TS-005: Audio Codec Display

**Feature:** F-005 — Audio Codec Display  
**Priority:** P1

---

#### TC-005.1: LDAC Codec Displayed

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; LDAC codec negotiated (check Android app for confirmation) |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Observe the "Audio Codec" row |
| **Expected Result** | Label displays "LDAC" with subtitle "High quality (48.0 kHz)" or similar quality descriptor. |
| **Pass Criteria** | "LDAC" displayed; matches Android app's codec indicator |

---

#### TC-005.2: AAC Codec Displayed

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; AAC codec active (may require forcing via system settings or during a phone call) |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Observe the "Audio Codec" row |
| **Expected Result** | Label displays "AAC" with subtitle "High quality". |
| **Pass Criteria** | "AAC" displayed correctly |

---

#### TC-005.3: SBC Codec Displayed

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; SBC codec active (fallback scenario) |
| **Steps** | 1. Open the popover |
|           | 2. Observe the "Audio Codec" row |
| **Expected Result** | Label displays "SBC" with subtitle "Standard quality". |
| **Pass Criteria** | "SBC" displayed correctly |

---

#### TC-005.4: Codec Display When Disconnected

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds NOT connected |
| **Steps** | 1. Open the popover |
|           | 2. Observe the codec row |
| **Expected Result** | Displays "—" or "Not connected". |
| **Pass Criteria** | No stale codec data shown |

---

#### TC-005.5: Codec Display is Read-Only (MVP)

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; codec displayed |
| **Steps** | 1. Click on the codec display row |
| **Expected Result** | Nothing happens — the codec display is read-only in MVP. No navigation, no picker, no sheet opens. |
| **Pass Criteria** | No interaction; display-only |

---

#### TC-005.6: Codec Updates When Changed

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; popover open; codec is LDAC |
| **Steps** | 1. Trigger a codec change (e.g., start a phone call which forces HFP/SBC, or change codec on Android) |
|           | 2. Observe the codec row in the macOS popover |
| **Expected Result** | Codec display updates to the new codec within 2 seconds. |
| **Pass Criteria** | Display reflects actual codec change |

---

### 2.6 TS-006: Menu Bar App (Popover)

**Feature:** F-006 — Menu Bar App  
**Priority:** P0

---

#### TC-006.1: Menu Bar Icon Present

| Field | Value |
|-------|-------|
| **Pre-conditions** | App is running |
| **Steps** | 1. Look at the macOS menu bar (right-hand status area) |
| **Expected Result** | A headphones SF Symbol icon is visible in the menu bar. |
| **Pass Criteria** | Icon present; recognizable as headphones |

---

#### TC-006.2: Popover Opens on Click

| Field | Value |
|-------|-------|
| **Pre-conditions** | App running; earbuds connected |
| **Steps** | 1. Click the headphones icon in the menu bar |
| **Expected Result** | A popover (approximately 320 × 480 pt) opens below the icon showing: device name, battery levels, ANC picker, ANC depth slider, codec display, "Open Settings…" button. |
| **Pass Criteria** | Popover opens with all expected content |

---

#### TC-006.3: Popover Closes on Outside Click

| Field | Value |
|-------|-------|
| **Pre-conditions** | Popover is open |
| **Steps** | 1. Click anywhere outside the popover (on the desktop or another window) |
| **Expected Result** | Popover closes. |
| **Pass Criteria** | Popover dismissed |

---

#### TC-006.4: Popover Closes on Esc Key

| Field | Value |
|-------|-------|
| **Pre-conditions** | Popover is open |
| **Steps** | 1. Press the Esc key |
| **Expected Result** | Popover closes. |
| **Pass Criteria** | Popover dismissed via keyboard |

---

#### TC-006.5: Popover Toggles on Repeated Click

| Field | Value |
|-------|-------|
| **Pre-conditions** | Popover is open |
| **Steps** | 1. Click the menu bar icon again |
| **Expected Result** | Popover closes (toggle behavior). |
| **Pass Criteria** | Second click closes popover |

---

#### TC-006.6: "Open Settings…" Opens Main Window

| Field | Value |
|-------|-------|
| **Pre-conditions** | Popover is open |
| **Steps** | 1. Click "Open Settings…" button in the popover |
| **Expected Result** | The main settings window opens (NavigationSplitView with sidebar). The popover closes. |
| **Pass Criteria** | Main window appears; popover dismisses |

---

#### TC-006.7: ⌘W Closes Main Window but Keeps Menu Bar

| Field | Value |
|-------|-------|
| **Pre-conditions** | Main settings window is open and focused |
| **Steps** | 1. Press ⌘W |
| **Expected Result** | The main window closes. The menu bar icon remains. The app continues running. |
| **Pass Criteria** | Window closed; icon persists; app alive |

---

#### TC-006.8: ⌘Q Quits the App Entirely

| Field | Value |
|-------|-------|
| **Pre-conditions** | App running (menu bar icon visible) |
| **Steps** | 1. Press ⌘Q (or right-click menu bar icon → Quit, if applicable) |
| **Expected Result** | The app quits. The menu bar icon disappears. |
| **Pass Criteria** | App fully terminated |

---

#### TC-006.9: App Launches to Menu Bar Only (No Window)

| Field | Value |
|-------|-------|
| **Pre-conditions** | App is not running |
| **Steps** | 1. Launch the app (double-click or from Launchpad) |
| **Expected Result** | The menu bar icon appears. No main window opens on launch. The app is ready in the background. |
| **Pass Criteria** | Icon appears; no window; background-ready |

---

#### TC-006.10: Popover Near Screen Edge

| Field | Value |
|-------|-------|
| **Pre-conditions** | Menu bar icon is near the right edge of the screen |
| **Steps** | 1. Click the menu bar icon |
| **Expected Result** | Popover opens and is fully visible on screen (NSPopover auto-repositions to avoid clipping). |
| **Pass Criteria** | No part of the popover is off-screen |

---

### 2.7 TS-007: Dark Mode + Light Mode

**Feature:** Cross-cutting — CR-1 through CR-5  
**Priority:** P0

---

#### TC-007.1: Light Mode Appearance

| Field | Value |
|-------|-------|
| **Pre-conditions** | macOS set to Light mode (System Settings → Appearance → Light) |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Open the main settings window |
|           | 3. Navigate through all pages (Overview, Noise Control) |
| **Expected Result** | All UI elements use light backgrounds, dark text, and appropriate contrast. No elements are invisible or hard to read. Battery colors are distinguishable. |
| **Pass Criteria** | Full visual inspection passes; no contrast issues |

---

#### TC-007.2: Dark Mode Appearance

| Field | Value |
|-------|-------|
| **Pre-conditions** | macOS set to Dark mode |
| **Steps** | 1. Open the menu bar popover |
|           | 2. Open the main settings window |
|           | 3. Navigate through all pages |
| **Expected Result** | All UI adapts to dark backgrounds, light text, and appropriate contrast. No hardcoded white backgrounds. Battery colors are distinguishable against dark backgrounds. |
| **Pass Criteria** | Full visual inspection passes; no hardcoded colors |

---

#### TC-007.3: Live Mode Switch

| Field | Value |
|-------|-------|
| **Pre-conditions** | App running; popover or main window visible |
| **Steps** | 1. Open System Settings → Appearance |
|           | 2. Switch between Light and Dark mode while the app UI is visible |
| **Expected Result** | The app UI updates immediately to reflect the new appearance. No restart required. No visual artifacts. |
| **Pass Criteria** | Live switch without artifacts |

---

### 2.8 TS-008: VoiceOver Accessibility

**Feature:** Cross-cutting — CR-6 through CR-13  
**Priority:** P0

---

#### TC-008.1: VoiceOver Reads Device Name

| Field | Value |
|-------|-------|
| **Pre-conditions** | VoiceOver enabled; earbuds connected; popover open |
| **Steps** | 1. Navigate VoiceOver cursor to the device name |
| **Expected Result** | VoiceOver reads: "REDMI Buds 8 Pro" (or the device's actual name). |
| **Pass Criteria** | Name announced correctly |

---

#### TC-008.2: VoiceOver Reads Battery Levels

| Field | Value |
|-------|-------|
| **Pre-conditions** | VoiceOver enabled; earbuds connected; popover open |
| **Steps** | 1. Navigate VoiceOver cursor to each battery indicator |
| **Expected Result** | VoiceOver reads: "Left earbud battery: 100 percent", "Right earbud battery: 100 percent", "Case battery: 1 percent" (values match displayed percentages). |
| **Pass Criteria** | All three batteries announced with correct values |

---

#### TC-008.3: VoiceOver Reads ANC Picker

| Field | Value |
|-------|-------|
| **Pre-conditions** | VoiceOver enabled; earbuds connected; popover open |
| **Steps** | 1. Navigate VoiceOver cursor to the ANC segmented picker |
| **Expected Result** | VoiceOver announces the current selection and available options: e.g., "Noise control: Noise Cancellation selected. Transparency, Noise Cancellation, Off." |
| **Pass Criteria** | Current mode and all options announced |

---

#### TC-008.4: VoiceOver Reads ANC Depth Slider

| Field | Value |
|-------|-------|
| **Pre-conditions** | VoiceOver enabled; slider enabled; popover open |
| **Steps** | 1. Navigate VoiceOver cursor to the ANC Depth slider |
| **Expected Result** | VoiceOver reads: "ANC Depth, [value] percent, adjustable. Light to Deep." |
| **Pass Criteria** | Slider value and range announced |

---

#### TC-008.5: VoiceOver Reads Codec Display

| Field | Value |
|-------|-------|
| **Pre-conditions** | VoiceOver enabled; earbuds connected; popover open |
| **Steps** | 1. Navigate VoiceOver cursor to the codec display |
| **Expected Result** | VoiceOver reads: "Audio codec: LDAC, High quality, 48 kilohertz" (or appropriate codec). |
| **Pass Criteria** | Codec name and quality announced |

---

#### TC-008.6: VoiceOver Reads Smart ANC Toggle

| Field | Value |
|-------|-------|
| **Pre-conditions** | VoiceOver enabled; main window open; Noise Control page |
| **Steps** | 1. Navigate VoiceOver cursor to the Smart ANC toggle |
| **Expected Result** | VoiceOver reads: "Smart Noise Cancellation, [on/off], toggle. When enabled, ANC depth adjusts automatically." |
| **Pass Criteria** | Toggle state and hint announced |

---

#### TC-008.7: Full Keyboard Tab Navigation (Popover)

| Field | Value |
|-------|-------|
| **Pre-conditions** | Popover open |
| **Steps** | 1. Press Tab repeatedly to cycle through all interactive controls |
|           | 2. Press Shift+Tab to navigate backwards |
| **Expected Result** | Focus moves sequentially through: ANC picker → ANC depth slider → "Open Settings…" button. Each focused element shows a visible focus ring. |
| **Pass Criteria** | All interactive controls reachable via Tab; focus ring visible |

---

#### TC-008.8: Full Keyboard Tab Navigation (Main Window)

| Field | Value |
|-------|-------|
| **Pre-conditions** | Main window open; Noise Control page |
| **Steps** | 1. Press Tab to cycle through all controls |
| **Expected Result** | Focus moves through: ANC picker → Smart ANC toggle → ANC depth slider → any additional controls. Focus ring visible on each. |
| **Pass Criteria** | All controls reachable; focus ring present |

---

### 2.9 TS-009: Error Handling & Disconnection

**Feature:** Cross-cutting — Section 6.5 of PRD  
**Priority:** P0

---

#### TC-009.1: Bluetooth Off on Mac

| Field | Value |
|-------|-------|
| **Pre-conditions** | Bluetooth turned OFF in System Settings |
| **Steps** | 1. Open the menu bar popover |
| **Expected Result** | Popover shows: "Bluetooth is turned off." with guidance to enable Bluetooth in System Settings. All controls disabled. |
| **Pass Criteria** | Helpful message displayed; no crash |

---

#### TC-009.2: Connection Drops While Popover Open

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; popover open |
| **Steps** | 1. Turn off the earbuds (or put them in the case and close the lid) |
|           | 2. Observe the popover |
| **Expected Result** | Status changes to "Reconnecting…". Battery values grey out or show "—". Controls become disabled. App begins auto-reconnect attempts. |
| **Pass Criteria** | Graceful degradation; "Reconnecting…" shown; no crash |

---

#### TC-009.3: Auto-Reconnect After Disconnection

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds were connected, then disconnected |
| **Steps** | 1. Turn earbuds back on / open the case |
|           | 2. Wait for reconnection |
| **Expected Result** | App detects the earbuds and reconnects within 3 seconds. Status returns to "Connected". Battery values and controls resume. All device state is re-read. |
| **Pass Criteria** | Auto-reconnect < 3 seconds; full state restored |

---

#### TC-009.4: BLE Command Timeout

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected but unresponsive (simulated or intermittent) |
| **Steps** | 1. Attempt to switch ANC mode |
|           | 2. BLE write times out (> 2 seconds with no ACK) |
| **Expected Result** | UI reverts the ANC picker to the previous mode. An inline error appears: "Failed to switch mode" (or similar). No crash. |
| **Pass Criteria** | Reverted state; error message; stable app |

---

#### TC-009.5: App Stability — 30-Minute Continuous Use

| Field | Value |
|-------|-------|
| **Pre-conditions** | Earbuds connected; app running |
| **Steps** | 1. Leave the app running for 30 minutes |
|           | 2. Periodically open/close the popover |
|           | 3. Switch ANC modes several times |
|           | 4. Open and close the main window |
| **Expected Result** | No crashes. No memory leaks (memory stays < 50 MB). CPU stays < 1% when idle. All features remain functional. |
| **Pass Criteria** | Zero crashes; memory < 50 MB; CPU < 1% idle |

---

### 2.10 TS-010: Performance

**Feature:** Cross-cutting — Section 6.4 of PRD  
**Priority:** P1

---

#### TC-010.1: App Launch Time

| Field | Value |
|-------|-------|
| **Pre-conditions** | App not running |
| **Steps** | 1. Launch the app |
|           | 2. Measure time until menu bar icon appears |
| **Expected Result** | Menu bar icon appears within 1 second of launch. |
| **Pass Criteria** | Launch < 1 second |

---

#### TC-010.2: Popover Open Time

| Field | Value |
|-------|-------|
| **Pre-conditions** | App running; menu bar icon visible |
| **Steps** | 1. Click the menu bar icon |
|           | 2. Measure time until popover fully renders |
| **Expected Result** | Popover opens and displays content within 100 ms. |
| **Pass Criteria** | Popover open < 100 ms (perceived as instant) |

---

#### TC-010.3: Memory Usage (Idle)

| Field | Value |
|-------|-------|
| **Pre-conditions** | App running; only menu bar icon visible; no windows open |
| **Steps** | 1. Open Activity Monitor |
|           | 2. Find the app process |
|           | 3. Check memory usage |
| **Expected Result** | Memory usage is < 30 MB. |
| **Pass Criteria** | Memory < 30 MB |

---

#### TC-010.4: Memory Usage (Main Window Open)

| Field | Value |
|-------|-------|
| **Pre-conditions** | App running; main settings window open |
| **Steps** | 1. Open Activity Monitor |
|           | 2. Check memory usage |
| **Expected Result** | Memory usage is < 50 MB. |
| **Pass Criteria** | Memory < 50 MB |

---

#### TC-010.5: CPU Usage (Idle)

| Field | Value |
|-------|-------|
| **Pre-conditions** | App running; idle (no user interaction for 1 minute) |
| **Steps** | 1. Open Activity Monitor |
|           | 2. Check CPU usage |
| **Expected Result** | CPU usage is < 1%. |
| **Pass Criteria** | CPU < 1% |

---

## 3. Test Execution Tracker

| Test Case | Description | Tester | Date | Result | Severity | Notes |
|-----------|-------------|--------|------|--------|----------|-------|
| TC-001.1 | Device name + image (connected) | | | | | |
| TC-001.2 | Battery levels displayed | | | | | |
| TC-001.3 | Battery color coding | | | | | |
| TC-001.4 | Battery real-time updates | | | | | |
| TC-001.5 | Disconnected state | | | | | |
| TC-001.6 | Overview in main window | | | | | |
| TC-002.1 | Switch to ANC | | | | | |
| TC-002.2 | Switch to Transparency | | | | | |
| TC-002.3 | Switch to Off | | | | | |
| TC-002.4 | ANC persists after popover close | | | | | |
| TC-002.5 | ANC disabled when disconnected | | | | | |
| TC-002.6 | ANC sync from physical gesture | | | | | |
| TC-002.7 | Rapid ANC toggling | | | | | |
| TC-002.8 | ANC in main window | | | | | |
| TC-003.1 | Enable Smart ANC | | | | | |
| TC-003.2 | Disable Smart ANC | | | | | |
| TC-003.3 | Smart ANC disabled (ANC Off) | | | | | |
| TC-003.4 | Smart ANC disabled (Transparency) | | | | | |
| TC-003.5 | Smart ANC state on reconnect | | | | | |
| TC-003.6 | Smart ANC toggle failure | | | | | |
| TC-004.1 | Slider adjusts ANC depth | | | | | |
| TC-004.2 | Slider labels visible | | | | | |
| TC-004.3 | Slider disabled (Smart ANC on) | | | | | |
| TC-004.4 | Slider disabled (ANC Off/Trans) | | | | | |
| TC-004.5 | Slider initial value from device | | | | | |
| TC-004.6 | Slider keyboard accessibility | | | | | |
| TC-004.7 | Slider in main window | | | | | |
| TC-005.1 | LDAC codec displayed | | | | | |
| TC-005.2 | AAC codec displayed | | | | | |
| TC-005.3 | SBC codec displayed | | | | | |
| TC-005.4 | Codec when disconnected | | | | | |
| TC-005.5 | Codec read-only | | | | | |
| TC-005.6 | Codec updates on change | | | | | |
| TC-006.1 | Menu bar icon present | | | | | |
| TC-006.2 | Popover opens on click | | | | | |
| TC-006.3 | Popover closes on outside click | | | | | |
| TC-006.4 | Popover closes on Esc | | | | | |
| TC-006.5 | Popover toggles on repeated click | | | | | |
| TC-006.6 | "Open Settings…" opens window | | | | | |
| TC-006.7 | ⌘W closes window, keeps menu bar | | | | | |
| TC-006.8 | ⌘Q quits app | | | | | |
| TC-006.9 | Launch to menu bar only | | | | | |
| TC-006.10 | Popover near screen edge | | | | | |
| TC-007.1 | Light mode appearance | | | | | |
| TC-007.2 | Dark mode appearance | | | | | |
| TC-007.3 | Live mode switch | | | | | |
| TC-008.1 | VO reads device name | | | | | |
| TC-008.2 | VO reads battery levels | | | | | |
| TC-008.3 | VO reads ANC picker | | | | | |
| TC-008.4 | VO reads ANC depth slider | | | | | |
| TC-008.5 | VO reads codec display | | | | | |
| TC-008.6 | VO reads Smart ANC toggle | | | | | |
| TC-008.7 | Keyboard nav (popover) | | | | | |
| TC-008.8 | Keyboard nav (main window) | | | | | |
| TC-009.1 | Bluetooth off on Mac | | | | | |
| TC-009.2 | Connection drops (popover open) | | | | | |
| TC-009.3 | Auto-reconnect | | | | | |
| TC-009.4 | BLE command timeout | | | | | |
| TC-009.5 | 30-minute stability | | | | | |
| TC-010.1 | App launch time | | | | | |
| TC-010.2 | Popover open time | | | | | |
| TC-010.3 | Memory (idle) | | | | | |
| TC-010.4 | Memory (window open) | | | | | |
| TC-010.5 | CPU (idle) | | | | | |

---

## 4. Summary

| Category | Test Scenarios | Test Cases |
|----------|---------------|------------|
| Device Overview (TS-001) | 6 | 6 |
| ANC Mode Toggle (TS-002) | 8 | 8 |
| Smart ANC Toggle (TS-003) | 6 | 6 |
| ANC Depth Slider (TS-004) | 7 | 7 |
| Audio Codec Display (TS-005) | 6 | 6 |
| Menu Bar App (TS-006) | 10 | 10 |
| Dark/Light Mode (TS-007) | 3 | 3 |
| VoiceOver Accessibility (TS-008) | 8 | 8 |
| Error Handling (TS-009) | 5 | 5 |
| Performance (TS-010) | 5 | 5 |
| **Total** | **64** | **64** |

---

*End of document.*
