import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esp_32_bluetooth/bluetooth/home/dataDisplayScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final flutterRelativeBle = FlutterReactiveBle();
  List<DiscoveredDevice> devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  ValueNotifier<Map<String, dynamic>> receivedData = ValueNotifier({});
  QualifiedCharacteristic? targetCharcter;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      devices.clear();
    });

    flutterRelativeBle.scanForDevices(withServices: []).listen((device) {
      if (device.name.isNotEmpty && !devices.any((d) => d.id == device.id)) {
        setState(() {
          devices.add(device);
        });
      }
    }, onError: (error) {
      if (kDebugMode) {
        print("Error scanning $error");
      }
      setState(() {
        _isScanning = false;
      });
    });
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      print("Attempting to connect to device: ${device.id}");
      await flutterRelativeBle
          .connectToDevice(
            id: device.id,
            connectionTimeout: const Duration(seconds: 10),
          )
          .first;
      print("Connected to device: ${device.id}");
      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });

      const String serviceUUID = "12345678-1234-1234-1234-123456789012";
      const String characteristicUUID = "abcdefab-1234-1234-1234-abcdefabcdef";

      targetCharcter = QualifiedCharacteristic(
        characteristicId: Uuid.parse(characteristicUUID),
        serviceId: Uuid.parse(serviceUUID),
        deviceId: device.id,
      );

      print("Subscribing to characteristic...");
      _readData();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DataDisplayScreen(sensorData: receivedData.value),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
      });
      if (kDebugMode) {
        print("Connection Failed: $e");
      }
    }
  }

  void _readData() {
    if (targetCharcter != null) {
      flutterRelativeBle.subscribeToCharacteristic(targetCharcter!).listen(
        (data) {
          try {
            String rawData = String.fromCharCodes(data);
            print("Raw Data: $rawData");

            // Parse data
            List<String> pairs = rawData.split(',');
            double? temp;
            double? hum;

            for (String pair in pairs) {
              List<String> keyValue = pair.split(':');
              if (keyValue.length == 2) {
                String key = keyValue[0].trim();
                String value = keyValue[1].trim();
                print("Parsed: $key, $value");
                if (key == "t") {
                  temp = double.tryParse(value);
                } else if (key == "h") {
                  hum = double.tryParse(value);
                }
              }
            }

            if (temp != null && hum != null) {
              print("Parsed Temperature: $temp, Humidity: $hum");

              // Write to Firestore
              FirebaseFirestore.instance.collection("sensor_data").add({
                "Temperature": temp,
                "Humidity": hum,
                "timestamp": DateTime.now().toIso8601String(),
              }).then((_) {
                print("Data successfully saved to Firestore");
              }).catchError((error) {
                print("Failed to save data: $error");
              });
            } else {
              print("Failed to parse temperature or humidity");
            }
          } catch (e) {
            print("Error parsing data: $e");
          }
        },
        onError: (error) {
          print("Error reading data: $error");
        },
      );
    } else {
      print("Target characteristic is null");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bluetooth Scanner",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _requestPermission();
          _startScan();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade100, Colors.teal.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Status: ${_isConnected ? 'Connected' : _isConnecting ? 'Connecting...' : 'Disconnected'}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isConnected
                            ? Colors.green
                            : _isConnecting
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startScan,
                      icon: Icon(_isScanning ? Icons.stop : Icons.search),
                      label: Text(_isScanning ? "Stop Scan" : "Start Scan"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          device.name.isNotEmpty
                              ? device.name
                              : "Unknown Device",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                        subtitle: Text(
                          device.id,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        trailing: _isConnecting && device.name == "MY_ESP32"
                            ? const CircularProgressIndicator()
                            : _isConnected && device.name == "MY_ESP32"
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                        onTap: () {
                          if (device.name == "MY_ESP32") {
                            _connectToDevice(device);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
