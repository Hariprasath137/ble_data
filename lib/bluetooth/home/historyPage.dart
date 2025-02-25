import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SensorHistoryPage extends StatelessWidget {
  final String sensorType;
  const SensorHistoryPage({super.key, required this.sensorType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${sensorType == "temp" ? "Temperature" : "Humidity"} History"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("sensor_data")
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              print("Error: ${snapshot.error}");
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print("No data available");
              return const Center(
                child: Text("No data available"),
              );
            }
            final data = snapshot.data!.docs;
            print("Snapshot Data: $data");
            return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final doc = data[index].data() as Map<String, dynamic>;
                  final value = sensorType == "temp"
                      ? doc["Temperature"]
                      : doc["Humidity"];
                  final timeStamp = doc["timestamp"];
                  return ListTile(
                    title: Text(
                      "$value ${sensorType == "temp" ? "°C" : "%"}",
                    ),
                    subtitle: Text(timeStamp.toString()),
                  );
                });
          }),
    );
  }
}