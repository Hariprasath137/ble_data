import bluetooth
from bleak import BleakScanner
import asyncio

def scan_classic_bluetooth():
    print("Scanning for Classic Bluetooth devices...")
    devices = bluetooth.discover_devices(duration=8, lookup_names=True)
    
    if devices:
        print("\n📡 Classic Bluetooth Devices Found:")
        for addr, name in devices:
            print(f"🔹 {name} - {addr}")
    else:
        print("\n❌ No Classic Bluetooth devices found.")

async def scan_ble():
    print("\nScanning for BLE devices...")
    devices = await BleakScanner.discover()
    
    if devices:
        print("\n📡 BLE Devices Found:")
        for device in devices:
            name = device.name if device.name else "Unknown"
            print(f"🔹 {name} - {device.address}")
    else:
        print("\n❌ No BLE devices found.")

def main():
    scan_classic_bluetooth()
    asyncio.run(scan_ble())

if __name__ == "__main__":
    main()
