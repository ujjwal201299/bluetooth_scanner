import 'package:flutter/material.dart';
import 'package:stratosfy_scanner_example/screens/geofence.dart';
import 'package:stratosfy_scanner_example/screens/scanner.dart';
import 'package:stratosfy_scanner_example/screens/telemetry_scanner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stratosfy Scanner"),
      ),
      body: Column(
        children: [
          // TODO:
          ListTile(
            title: Text("Telemetry Scanner"),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TelemetryScanner()));
            },
          ),
          ListTile(
            title: Text("iBeacon Scanner"),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ScannerScreen()));
            },
          ),
          ListTile(
            title: Text("Geofence Screen"),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => GeofenceScreen()));
            },
          )
        ],
      ),
    );
  }
}
