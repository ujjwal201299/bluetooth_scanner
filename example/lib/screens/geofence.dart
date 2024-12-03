import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stratosfy_scanner/stratosfy_scanner.dart';

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({Key? key}) : super(key: key);

  @override
  _GeofenceScreenState createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  Geofence _geofence = Geofence(
    identifier: Random().nextInt(100000000).toString(),
    latitude: 27.661531,
    longitude: 83.465614,
    radius: 200,
    customData: {"name": "aawaz"},
  );

  @override
  void dispose() {
    snowmScanner.removeGeofence(_geofence.identifier);
    snowmScanner.removeAllGeofence();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    snowmScanner.requestPermission();
  }

  _startScanning() {
    snowmScanner.registerGeofence(_geofence);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Geofence Example"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextFormField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Lat",
              ),
              initialValue: _geofence.latitude.toString(),
              onChanged: (v) {
                _geofence.latitude = double.tryParse(v)!;
              },
            ),
            TextFormField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Long",
              ),
              initialValue: _geofence.longitude.toString(),
              onChanged: (v) {
                _geofence.longitude = double.tryParse(v)!;
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Radius",
              ),
              initialValue: _geofence.radius.toString(),
              onChanged: (v) {
                _geofence.radius = int.tryParse(v)!;
              },
            ),
            TextButton(
              child: Text("Register"),
              onPressed: _startScanning,
            )
          ],
        ),
      ),
    );
  }
}
