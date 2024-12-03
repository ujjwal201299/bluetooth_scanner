import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stratosfy_scanner/stratosfy_scanner.dart';
import 'package:stratosfy_scanner_example/widgets/device.dart';

class TelemetryScanner extends StatefulWidget {
  const TelemetryScanner({Key? key}) : super(key: key);

  @override
  _TelemetryScannerState createState() => _TelemetryScannerState();
}

class _TelemetryScannerState extends State<TelemetryScanner> {
  StreamSubscription? controller1;
  bool isScanningTele = false;

  List<StratosfyDevice> rawDatas = [];
  Map<String, StratosfyDevice> deviceData = {};

  manageTelemetryButton() async {
    if (controller1 == null) {
      setState(() {
        isScanningTele = false;
      });
      Stream<StratosfyDevice> abc = await snowmScanner.scanTelemetry();
     controller1= abc.listen((event) {
        deviceData[event.macAddress!] = event;
        rawDatas = deviceData.values.toList();
        setState(() {});
      });
    } else {
      rawDatas = [];
      snowmScanner.stopScanningTelemetry();
      controller1!.cancel();
      controller1 = null;
      setState(() {
        isScanningTele = false;
      });
    }
  }

  @override
  void dispose() {
    controller1?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Telemetry Scanner")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(
                controller1 == null
                    ? "Scan telemetry Beacons"
                    : "Stop telemetry Scanning",
              ),
              onTap: () async {
                await manageTelemetryButton();
              },
            ),
            for (StratosfyDevice packet in rawDatas)
              StratosfyDeviceCard(device: packet),
          ],
        ),
      ),
    );
  }
}
