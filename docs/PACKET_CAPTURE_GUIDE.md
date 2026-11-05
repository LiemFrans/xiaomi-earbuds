# 📡 Bluetooth Packet Capture Guide

**Purpose:** Capture and analyze Bluetooth HCI traffic between the REDMI Buds 8 Pro and host devices to reverse-engineer the proprietary protocol.

---

## Table of Contents

1. [macOS PacketLogger Setup](#1-macos-packetlogger-setup)
2. [Android HCI Snoop Log](#2-android-hci-snoop-log)
3. [Wireshark Analysis](#3-wireshark-analysis)
4. [Tips for Isolating Commands](#4-tips-for-isolating-commands)
5. [Exporting and Sharing Captures](#5-exporting-and-sharing-captures)

---

## 1. macOS PacketLogger Setup

### 1.1 Prerequisites

- macOS 13+ (Ventura or later)
- Xcode (or Additional Tools for Xcode) installed
- Admin access for enabling Bluetooth debug logging

### 1.2 Install PacketLogger

PacketLogger is included in the **Additional Tools for Xcode** package:

1. Open Xcode → **Xcode** menu → **Open Developer Tool** → **More Developer Tools…**
2. This opens the Apple Developer downloads page.
3. Download **Additional Tools for Xcode** (match your Xcode version).
4. Mount the DMG and find `PacketLogger.app` in the **Hardware** folder.
5. Copy it to `/Applications` or a convenient location.

Alternatively, if you have the Xcode command line tools:
```bash
# Check if PacketLogger is available
find /Applications/Xcode.app -name "PacketLogger.app" 2>/dev/null
# It may be at:
# /Applications/Xcode.app/Contents/Applications/PacketLogger.app
```

### 1.3 Enable Bluetooth Debug Logging

```bash
# Enable Bluetooth packet logging (requires restart of Bluetooth daemon)
sudo defaults write com.apple.BlueTool DebugEnabled -bool true
sudo defaults write com.apple.bluetooth.btsnoop EnableBtSnoopLog -bool true

# Restart Bluetooth
sudo pkill bluetoothd
# or toggle Bluetooth off/on via System Settings
```

### 1.4 Capture with PacketLogger

1. Open **PacketLogger.app**.
2. Click **File** → **New Trace** (or ⌘N).
3. Select the Bluetooth interface (usually `en0` or the default).
4. Click **Start** to begin capture.
5. Perform the actions you want to capture (pair device, change ANC, etc.).
6. Click **Stop** when done.
7. Save the trace: **File** → **Save** (`.pklg` format).

### 1.5 PacketLogger Filters

Use the filter bar to isolate relevant traffic:

| Filter | Purpose |
|--------|---------|
| `hci` | All HCI packets |
| `l2cap` | L2CAP channel data |
| `att` | ATT/GATT operations |
| `smp` | Security Manager Protocol |
| `rfcomm` | RFCOMM/SPP data |
| `acl` | ACL data packets |

To filter by device address:
- Use the **Device** column or filter by the BD_ADDR.
- Right-click a packet from the target device → **Set as Filter**.

### 1.6 Export for Wireshark

PacketLogger can export captures in BTSnoop format:

1. **File** → **Export** → **BTSnoop**.
2. Save as `.log` or `.cap` file.
3. Open in Wireshark for advanced analysis.

---

## 2. Android HCI Snoop Log

Use an Android device paired with the REDMI Buds 8 Pro to capture traffic from the Xiaomi Earbuds app.

### 2.1 Enable HCI Snoop Log

1. Enable **Developer Options** on Android:
   - **Settings** → **About Phone** → Tap **Build Number** 7 times.
2. Go to **Settings** → **Developer Options**.
3. Enable **Enable Bluetooth HCI snoop log**.
4. **Restart Bluetooth** (toggle off/on) for the setting to take effect.

### 2.2 Capture Traffic

1. Open the **Xiaomi Earbuds** app on Android.
2. Connect to the REDMI Buds 8 Pro.
3. Perform the actions you want to analyze:
   - Change ANC mode
   - Adjust ANC depth
   - Switch codecs
   - Configure gestures
   - Toggle spatial audio
   - etc.
4. After capturing, disable the HCI snoop log.

### 2.3 Retrieve the Log File

The HCI snoop log location varies by Android version and manufacturer:

```bash
# Common locations:
adb pull /sdcard/btsnoop_hci.log ./btsnoop_hci.log
adb pull /data/misc/bluetooth/logs/btsnoop_hci.log ./btsnoop_hci.log
adb pull /sdcard/Android/data/btsnoop_hci.log ./btsnoop_hci.log

# On newer Android (12+), use bug report:
adb bugreport bugreport.zip
# Extract btsnoop_hci.log from the zip
unzip bugreport.zip -d bugreport/
find bugreport/ -name "btsnoop_hci.log"
```

### 2.4 Quick Verification

```bash
# Check if the file is a valid BTSnoop file
file btsnoop_hci.log
# Should output: "BTSnoop version 1, HCI UART (H4)"

# Check file size (should be > 0)
ls -la btsnoop_hci.log
```

---

## 3. Wireshark Analysis

### 3.1 Install Wireshark

```bash
# macOS (Homebrew)
brew install --cask wireshark

# Or download from https://www.wireshark.org/download.html
```

### 3.2 Open Capture Files

- Open `.pklg` files from PacketLogger directly in Wireshark.
- Open `.log` BTSnoop files from Android.
- Wireshark auto-detects the Bluetooth HCI format.

### 3.3 Useful Display Filters

| Filter | Purpose |
|--------|---------|
| `bluetooth` | All Bluetooth traffic |
| `btatt` | ATT protocol (GATT reads/writes) |
| `btatt.opcode == 0x12` | ATT Write Request |
| `btatt.opcode == 0x1b` | ATT Handle Value Notification |
| `btatt.opcode == 0x0a` | ATT Read Request |
| `btatt.opcode == 0x0b` | ATT Read Response |
| `btgatt` | GATT operations |
| `bthci_acl` | ACL data |
| `bthci_evt` | HCI events |
| `btrfcomm` | RFCOMM data |
| `btl2cap` | L2CAP frames |
| `bluetooth.addr == B8:53:84:6B:BD:88` | Filter by device address |
| `btatt.handle == 0x0025` | Filter by ATT handle |

### 3.4 Analyzing GATT Write/Notify for Proprietary Protocol

The Xiaomi proprietary commands will appear as ATT Write Requests and Handle Value Notifications on the custom characteristic handles.

**Step-by-step:**

1. **Find the custom service handles:**
   ```
   Filter: btatt.opcode == 0x10 || btatt.opcode == 0x11
   ```
   This shows "Read By Group Type" responses that list services with their handle ranges.

2. **Find writes to the command characteristic:**
   ```
   Filter: btatt.opcode == 0x12 && btatt.handle == <COMMAND_HANDLE>
   ```

3. **Find notifications from the response characteristic:**
   ```
   Filter: btatt.opcode == 0x1b && btatt.handle == <RESPONSE_HANDLE>
   ```

4. **Extract the raw payload:**
   - Right-click the ATT value field → **Copy** → **as Hex Stream**.
   - Look for the `FEDC` magic bytes at the start.

### 3.5 Useful Wireshark Columns

Add custom columns for easier analysis:

1. **Edit** → **Preferences** → **Columns**.
2. Add:
   | Title | Field | Type |
   |-------|-------|------|
   | ATT Opcode | `btatt.opcode` | Custom |
   | ATT Handle | `btatt.handle` | Custom |
   | ATT Value | `btatt.value` | Custom |
   | Direction | `hci_h4.direction` | Custom |

### 3.6 Wireshark CLI (tshark)

For batch analysis from the command line:

```bash
# List all ATT write requests
tshark -r btsnoop_hci.log -Y "btatt.opcode == 0x12" -T fields \
  -e frame.number -e frame.time_relative -e btatt.handle -e btatt.value

# List all notifications
tshark -r btsnoop_hci.log -Y "btatt.opcode == 0x1b" -T fields \
  -e frame.number -e frame.time_relative -e btatt.handle -e btatt.value

# Filter for specific device and export
tshark -r btsnoop_hci.log \
  -Y "bluetooth.addr == B8:53:84:6B:BD:88 && (btatt.opcode == 0x12 || btatt.opcode == 0x1b)" \
  -T fields -e frame.number -e btatt.opcode -e btatt.value \
  > xiaomi_protocol_dump.txt
```

---

## 4. Tips for Isolating Commands

### 4.1 Capture Strategy

To identify which bytes correspond to a specific command, perform **one action at a time** with clear pauses between actions:

1. **Start capture.**
2. **Wait 5 seconds** (establish baseline).
3. **Perform ONE action** (e.g., switch ANC from Off to Noise Cancellation).
4. **Wait 5 seconds.**
5. **Perform the reverse action** (e.g., switch back to Off).
6. **Wait 5 seconds.**
7. **Stop capture.**

This creates a clear "before/during/after" pattern in the capture that makes it easy to identify the command and response.

### 4.2 Recommended Capture Sequence

Run each action in a separate capture session for clarity:

| Session | Action | Expected Command |
|---------|--------|-----------------|
| 1 | Open app → read initial state | GET_BATTERY, GET_ANC_MODE, GET_CODEC, etc. |
| 2 | Toggle ANC: Off → NC → Transparency → Off | SET_ANC_MODE with different values |
| 3 | Adjust ANC depth slider | SET_ANC_DEPTH with varying values |
| 4 | Switch codec: LDAC → AAC → SBC → LDAC | SET_CODEC |
| 5 | Change sound mode through all presets | SET_SOUND_MODE |
| 6 | Toggle spatial audio on/off | SET_SPATIAL_AUDIO |
| 7 | Toggle head tracking on/off | SET_HEAD_TRACKING |
| 8 | Change gesture mappings | SET_GESTURE_CONFIG |
| 9 | Start/stop find device | FIND_DEVICE |
| 10 | Run ear tip fit test | START_EAR_TIP_FIT_TEST |

### 4.3 Identifying the Protocol Frame

Once you have a capture with known actions:

1. **Filter for ATT writes and notifications** as shown above.
2. **Look for the magic bytes** `FE DC` at the start of ATT values.
3. **Correlate timing:** The write just before your action is the command; the notification just after is the response.
4. **Compare multiple captures** of the same action to identify constant bytes (opcode, magic) vs. variable bytes (sequence number, payload, CRC).

### 4.4 Diffing Captures

Save multiple captures of the same action and diff them:

```bash
# Extract commands from two captures
tshark -r capture1.log -Y "btatt.opcode == 0x12" -T fields -e btatt.value > cmd1.txt
tshark -r capture2.log -Y "btatt.opcode == 0x12" -T fields -e btatt.value > cmd2.txt

# Diff to see which bytes change (sequence number, CRC)
diff cmd1.txt cmd2.txt
```

---

## 5. Exporting and Sharing Captures

### 5.1 File Formats

| Format | Extension | Tool | Notes |
|--------|-----------|------|-------|
| PacketLogger | `.pklg` | PacketLogger | macOS native |
| BTSnoop | `.log` | Android / Wireshark | Standard BT capture format |
| pcapng | `.pcapng` | Wireshark | Universal packet capture |
| pcap | `.pcap` | Wireshark / tshark | Legacy format |

### 5.2 Converting Formats

```bash
# Convert PacketLogger to pcapng
editcap -F pcapng capture.pklg capture.pcapng

# Convert BTSnoop to pcapng
editcap -F pcapng btsnoop_hci.log capture.pcapng

# Extract only Xiaomi-relevant frames
tshark -r full_capture.pcapng \
  -Y "bluetooth.addr == B8:53:84:6B:BD:88" \
  -w xiaomi_only.pcapng
```

### 5.3 Sanitizing Captures Before Sharing

Remove sensitive data before sharing captures with the team:

```bash
# Anonymize Bluetooth addresses (optional)
editcap --seed 42 -T ether capture.pcapng anonymized.pcapng
```

> **⚠️ Warning:** BT captures may contain device serial numbers, MAC addresses, and paired device information. Sanitize before sharing publicly.

### 5.4 Storing Captures

Store raw captures in the project under `captures/` (git-ignored for size):

```
captures/
├── 2026-11-05_anc_mode_toggle.pklg
├── 2026-11-05_codec_switch.pklg
├── 2026-11-05_initial_connection.log
└── README.md  (capture session notes)
```

Add to `.gitignore`:
```
captures/*.pklg
captures/*.log
captures/*.pcapng
```
