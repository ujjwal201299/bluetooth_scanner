import 'package:flutter/material.dart';
import 'package:stratosfy_scanner_example/screens/scanner.dart';
import 'package:stratosfy_scanner_example/screens/telemetry_scanner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
      routes: {
        "/scanner": (_) => ScannerScreen(),
        "/telemetry-scanner": (_) => TelemetryScanner(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stratosy Scanner"),
      ),
      body: Column(
        children: [
          // ListTile(
          //   title: Text("Scanner"),
          //   onTap: () {
          //     print("scanner pressed");
          //     Navigator.pushNamed(context, "/scanner");
          //   },
          // ),
          ListTile(
            title: Text("Telemetry Scanner"),
            onTap: () {
              print("scanner pressed");
              Navigator.pushNamed(context, "/telemetry-scanner");
            },
          )
        ],
      ),
    );
  }
}
