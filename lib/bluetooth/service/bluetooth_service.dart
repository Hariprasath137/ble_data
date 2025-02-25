// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

// class BluetoothService {
//   final FlutterReactiveBle _ble = FlutterReactiveBle();

//   Stream<List<DiscoveredDevice>> scanForDevices() {
//     return _ble.scanForDevices(withServices: []).map((device) => [device]);
//   }

//   Future<void> connectToDevice(DiscoveredDevice device) async {
//     await _ble.connectToDevice(id: device.id).first;
//   }

//   Future<bool> isBluetoothEnabled() async {
//   return await _ble.statusStream.first == BleStatus.ready;
// }


//   Future<String?> readData(String deviceId, Uuid characteristicId) async {
//     final characteristic = QualifiedCharacteristic(
//       serviceId: Uuid.parse("0000180D-0000-1000-8000-00805f9b34fb"), // Example service UUID
//       characteristicId: characteristicId,
//       deviceId: deviceId,
//     );

//     List<int> data = await _ble.readCharacteristic(characteristic);
//     return String.fromCharCodes(data);
//   }
// }
