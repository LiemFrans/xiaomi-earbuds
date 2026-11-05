#!/usr/bin/env python3
"""
BLE GATT Enumeration Script for REDMI Buds 8 Pro

Scans, connects, and enumerates all BLE services, characteristics,
and descriptors on the target device. Reads readable values and
subscribes to notification characteristics.

Requirements:
    pip install bleak

Usage:
    python ble_scanner.py --address B8:53:84:6B:BD:88
    python ble_scanner.py --name "REDMI Buds 8 Pro"
    python ble_scanner.py --scan  # Discover nearby BLE devices
"""

from __future__ import annotations

import argparse
import asyncio
import logging
import struct
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

try:
    from bleak import BleakClient, BleakScanner
    from bleak.backends.characteristic import BleakGATTCharacteristic
    from bleak.backends.descriptor import BleakGATTDescriptor
    from bleak.backends.service import BleakGATTService
except ImportError:
    print("Error: bleak is required. Install with: pip install bleak")
    sys.exit(1)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Well-known BLE UUIDs
# ---------------------------------------------------------------------------
KNOWN_SERVICES: dict[str, str] = {
    "00001800-0000-1000-8000-00805f9b34fb": "Generic Access",
    "00001801-0000-1000-8000-00805f9b34fb": "Generic Attribute",
    "0000180a-0000-1000-8000-00805f9b34fb": "Device Information",
    "0000180f-0000-1000-8000-00805f9b34fb": "Battery Service",
    "0000febe-0000-1000-8000-00805f9b34fb": "Xiaomi MiService",
    "0000fee0-0000-1000-8000-00805f9b34fb": "Xiaomi Mi Band / Earbuds",
    "0000fee1-0000-1000-8000-00805f9b34fb": "Xiaomi Auth Service",
    "00010203-0405-0607-0809-0a0b0c0d0e0f": "Xiaomi Custom GATT (variant)",
}

KNOWN_CHARACTERISTICS: dict[str, str] = {
    "00002a00-0000-1000-8000-00805f9b34fb": "Device Name",
    "00002a01-0000-1000-8000-00805f9b34fb": "Appearance",
    "00002a04-0000-1000-8000-00805f9b34fb": "Peripheral Preferred Connection Parameters",
    "00002a19-0000-1000-8000-00805f9b34fb": "Battery Level",
    "00002a24-0000-1000-8000-00805f9b34fb": "Model Number String",
    "00002a25-0000-1000-8000-00805f9b34fb": "Serial Number String",
    "00002a26-0000-1000-8000-00805f9b34fb": "Firmware Revision String",
    "00002a27-0000-1000-8000-00805f9b34fb": "Hardware Revision String",
    "00002a28-0000-1000-8000-00805f9b34fb": "Software Revision String",
    "00002a29-0000-1000-8000-00805f9b34fb": "Manufacturer Name String",
    "00002a50-0000-1000-8000-00805f9b34fb": "PnP ID",
}

KNOWN_DESCRIPTORS: dict[str, str] = {
    "00002900-0000-1000-8000-00805f9b34fb": "Characteristic Extended Properties",
    "00002901-0000-1000-8000-00805f9b34fb": "Characteristic User Description",
    "00002902-0000-1000-8000-00805f9b34fb": "Client Characteristic Configuration",
    "00002903-0000-1000-8000-00805f9b34fb": "Server Characteristic Configuration",
}

# Target device identifiers
REDMI_BUDS_NAMES = [
    "REDMI Buds 8 Pro",
    "Redmi Buds 8 Pro",
    "XIAOMI Buds 8 Pro",
]


def _props_str(characteristic: BleakGATTCharacteristic) -> str:
    """Return a human-readable string of characteristic properties."""
    return ", ".join(sorted(characteristic.properties))


def _friendly_name(uuid: str, lookup: dict[str, str]) -> str:
    """Return the friendly name for a UUID if known."""
    name = lookup.get(uuid.lower(), "")
    return f" ({name})" if name else ""


def _hex_dump(data: bytes, max_bytes: int = 64) -> str:
    """Format bytes as a hex dump string."""
    hex_str = data[:max_bytes].hex(" ")
    if len(data) > max_bytes:
        hex_str += f" ... ({len(data)} bytes total)"
    return hex_str


def _try_decode_string(data: bytes) -> Optional[str]:
    """Try to decode raw bytes as a UTF-8 string."""
    try:
        decoded = data.decode("utf-8").strip("\x00")
        if decoded.isprintable() and len(decoded) > 0:
            return decoded
    except (UnicodeDecodeError, ValueError):
        pass
    return None


# ---------------------------------------------------------------------------
# Notification handler
# ---------------------------------------------------------------------------
_notification_log: list[tuple[str, datetime, bytes]] = []


def _notification_handler(characteristic: BleakGATTCharacteristic, data: bytearray):
    """Callback for BLE notifications."""
    now = datetime.now()
    _notification_log.append((characteristic.uuid, now, bytes(data)))
    friendly = _friendly_name(characteristic.uuid, KNOWN_CHARACTERISTICS)
    log.info(
        "NOTIFY %s%s: %s",
        characteristic.uuid,
        friendly,
        _hex_dump(data),
    )
    decoded = _try_decode_string(data)
    if decoded:
        log.info("  -> decoded string: %r", decoded)
    if len(data) == 1:
        log.info("  -> uint8 value: %d", data[0])
    elif len(data) == 2:
        val_le = struct.unpack("<H", data)[0]
        log.info("  -> uint16 (LE): %d", val_le)


# ---------------------------------------------------------------------------
# Core enumeration
# ---------------------------------------------------------------------------
async def scan_devices(timeout: float = 10.0) -> None:
    """Scan for nearby BLE devices and print results."""
    log.info("Scanning for BLE devices (%.0fs)...", timeout)
    devices = await BleakScanner.discover(timeout=timeout)
    if not devices:
        log.warning("No BLE devices found.")
        return
    print(f"\n{'Address':<20} {'RSSI':>5}  {'Name'}")
    print("-" * 60)
    for d in sorted(devices, key=lambda x: x.rssi or -999, reverse=True):
        name = d.name or "(unknown)"
        rssi = d.rssi if d.rssi is not None else "?"
        marker = " <-- TARGET" if name in REDMI_BUDS_NAMES else ""
        print(f"{d.address:<20} {rssi:>5}  {name}{marker}")
    print(f"\nTotal: {len(devices)} devices found.")


async def find_device_by_name(
    name_filter: str, timeout: float = 10.0
) -> Optional[str]:
    """Scan for a device matching the given name and return its address."""
    log.info("Scanning for device named '%s'...", name_filter)
    devices = await BleakScanner.discover(timeout=timeout)
    name_lower = name_filter.lower()
    for d in devices:
        if d.name and name_lower in d.name.lower():
            log.info("Found: %s (%s, RSSI=%s)", d.name, d.address, d.rssi)
            return d.address
    return None


async def enumerate_gatt(
    address: str,
    subscribe_timeout: float = 5.0,
    output_file: Optional[Path] = None,
) -> None:
    """Connect to a device and enumerate all GATT services."""
    log.info("Connecting to %s ...", address)
    lines: list[str] = []

    def emit(msg: str = "") -> None:
        print(msg)
        lines.append(msg)

    async with BleakClient(address, timeout=20.0) as client:
        if not client.is_connected:
            log.error("Failed to connect to %s", address)
            return

        log.info("Connected! MTU = %d", client.mtu_size)
        emit(f"\n{'=' * 72}")
        emit(f"  BLE GATT Enumeration — {address}")
        emit(f"  Connected at {datetime.now().isoformat()}")
        emit(f"  MTU: {client.mtu_size}")
        emit(f"{'=' * 72}\n")

        services = client.services
        emit(f"Total services: {len(services)}\n")

        notification_chars: list[BleakGATTCharacteristic] = []

        for service in services:
            svc_name = _friendly_name(service.uuid, KNOWN_SERVICES)
            emit(f"┌─ Service: {service.uuid}{svc_name}")
            emit(f"│  Handle: 0x{service.handle:04X}")

            for char in service.characteristics:
                char_name = _friendly_name(char.uuid, KNOWN_CHARACTERISTICS)
                emit(f"│  ├─ Characteristic: {char.uuid}{char_name}")
                emit(f"│  │  Handle: 0x{char.handle:04X}")
                emit(f"│  │  Properties: {_props_str(char)}")

                # Try to read the value
                if "read" in char.properties:
                    try:
                        value = await client.read_gatt_char(char)
                        emit(f"│  │  Value (hex): {_hex_dump(value)}")
                        decoded = _try_decode_string(value)
                        if decoded:
                            emit(f"│  │  Value (str): {decoded!r}")
                        if len(value) == 1:
                            emit(f"│  │  Value (uint8): {value[0]}")
                        elif len(value) == 2:
                            val = struct.unpack("<H", value)[0]
                            emit(f"│  │  Value (uint16 LE): {val}")
                    except Exception as e:
                        emit(f"│  │  Read error: {e}")

                # Track notification/indicate characteristics
                if "notify" in char.properties or "indicate" in char.properties:
                    notification_chars.append(char)

                # List descriptors
                for desc in char.descriptors:
                    desc_name = _friendly_name(desc.uuid, KNOWN_DESCRIPTORS)
                    emit(f"│  │  └─ Descriptor: {desc.uuid}{desc_name}")
                    emit(f"│  │     Handle: 0x{desc.handle:04X}")
                    try:
                        desc_val = await client.read_gatt_descriptor(desc.handle)
                        emit(f"│  │     Value: {_hex_dump(desc_val)}")
                    except Exception as e:
                        emit(f"│  │     Read error: {e}")

            emit("└─")
            emit("")

        # Subscribe to notification characteristics
        if notification_chars:
            emit(f"\n{'─' * 72}")
            emit(f"Subscribing to {len(notification_chars)} notification/indicate characteristic(s)...")
            emit(f"Listening for {subscribe_timeout:.0f} seconds...\n")

            for char in notification_chars:
                try:
                    await client.start_notify(char, _notification_handler)
                    char_name = _friendly_name(char.uuid, KNOWN_CHARACTERISTICS)
                    log.info("Subscribed to %s%s", char.uuid, char_name)
                except Exception as e:
                    log.warning("Could not subscribe to %s: %s", char.uuid, e)

            await asyncio.sleep(subscribe_timeout)

            for char in notification_chars:
                try:
                    await client.stop_notify(char)
                except Exception:
                    pass

            if _notification_log:
                emit(f"\nReceived {len(_notification_log)} notification(s):")
                for uuid, ts, data in _notification_log:
                    friendly = _friendly_name(uuid, KNOWN_CHARACTERISTICS)
                    emit(f"  [{ts.strftime('%H:%M:%S.%f')}] {uuid}{friendly}: {_hex_dump(data)}")
            else:
                emit("No notifications received during the listening period.")

    emit(f"\nDisconnected from {address}.")

    if output_file:
        output_file.write_text("\n".join(lines), encoding="utf-8")
        log.info("Output saved to %s", output_file)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(
        description="BLE GATT Enumeration for REDMI Buds 8 Pro",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
Examples:
  %(prog)s --scan
  %(prog)s --address B8:53:84:6B:BD:88
  %(prog)s --name "REDMI Buds 8 Pro"
  %(prog)s --address B8:53:84:6B:BD:88 --output gatt_dump.txt
  %(prog)s --address B8:53:84:6B:BD:88 --subscribe-timeout 30
""",
    )
    parser.add_argument(
        "--scan",
        action="store_true",
        help="Scan for nearby BLE devices and exit.",
    )
    parser.add_argument(
        "--address",
        type=str,
        help="BLE address to connect to (e.g., B8:53:84:6B:BD:88).",
    )
    parser.add_argument(
        "--name",
        type=str,
        help="Device name to search for (e.g., 'REDMI Buds 8 Pro').",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Save enumeration output to a text file.",
    )
    parser.add_argument(
        "--subscribe-timeout",
        type=float,
        default=5.0,
        help="Seconds to listen for notifications (default: 5).",
    )
    parser.add_argument(
        "--scan-timeout",
        type=float,
        default=10.0,
        help="Seconds to scan for devices (default: 10).",
    )

    args = parser.parse_args()

    if args.scan:
        asyncio.run(scan_devices(timeout=args.scan_timeout))
        return

    address = args.address
    if not address and args.name:
        address = asyncio.run(
            find_device_by_name(args.name, timeout=args.scan_timeout)
        )
        if not address:
            log.error("Device '%s' not found.", args.name)
            sys.exit(1)

    if not address:
        parser.error("Provide --address, --name, or --scan.")

    asyncio.run(
        enumerate_gatt(
            address=address,
            subscribe_timeout=args.subscribe_timeout,
            output_file=args.output,
        )
    )


if __name__ == "__main__":
    main()
