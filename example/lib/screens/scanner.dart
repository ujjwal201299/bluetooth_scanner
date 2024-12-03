// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stratosfy_scanner/stratosfy_scanner.dart';
import 'package:stratosfy_scanner_example/widgets/bluetooth_status.dart';


class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isScanning = false;

  List<SnowMBeacon> scannedBeacons = [];
  double? radius;

  var sKey = GlobalKey<ScaffoldState>();
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? snackbar;
  List<String> uuids = [];

  var _uuidController = TextEditingController();
  StreamSubscription? controller;

  scanBeacons() {
    setState(() {
      isScanning = true;
    });
    controller = snowmScanner
        .scanIBeacons(
            uuids: uuids, scanAllIBeacons: Platform.isAndroid ? true : false)
        .listen((beacons) {
      setState(() {
        this.scannedBeacons = beacons;
      });
    });
  }

  void backgroundScanning() async {
    await snowmScanner.scanIBeaconsInBackground(
      "scannerId",
      uuids,
      geofences: [
        Geofence(
          identifier: "background",
          latitude: 27.742483,
          longitude: 85.3123,
          radius: 1000,
        ),
      ],
      customData: {
        "hello": "world",
      },
      title: "SnowM Scanner Testing",
      body: "Testing scanner",
    );
    initAsync();
  }

  manageButton() {
    if (controller == null)
      scanBeacons();
    else
      stopScan();
  }

  stopScan() {
    controller!.cancel();
    controller = null;
    setState(() {
      isScanning = false;
    });
  }

  showSnackbar(String message) {
    snackbar = ScaffoldMessenger.of(sKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    print("Scanner screens initState");
    initAsync();
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   initAsync();
    // });
  }

  SharedPreferences? prefs;

  initAsync() async {
    print("scanner initAsync");
    snowmScanner.configure(enableMqtt: true);
    print("scanner configures");
    snowmScanner.isTransmitting().then((value) {
      print("scanner isTransmitting $value");
      setState(() {
        this.isTransmitting = value!;
      });
    });
    prefs = await SharedPreferences.getInstance();
    id = (await snowmScanner.getCurrentScanId())!;
    print("checking ID $id");
    setState(() {
      // uuids = prefs.getStringList("uuids") ?? [];
    });
  }

  get hasScanId => id != null;

  String? id;
  bool isTransmitting = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: sKey,
      appBar: AppBar(
        title: Text("Stratosfy Scanner"),
      ),
      body: Column(
        children: <Widget>[
          BluetoothStatus(),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text(
                      "Beacons to Scan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (String uuid in uuids)
                    ListTile(
                      title: Text(uuid),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            uuids.removeWhere((element) => element == uuid);
                            prefs!.setStringList("uuids", uuids);
                          });
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: TextField(
                      controller: _uuidController,
                      decoration: InputDecoration(
                        hintText: 'eg:42524149-4e41-4e54-5330-303030303036',
                        labelText: 'Add UUID to scan',
                        suffixIcon: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              if (_uuidController != null &&
                                  _uuidController.text.isNotEmpty) {
                                setState(() {
                                  uuids.add(_uuidController.text);
                                  _uuidController.clear();
                                  prefs!.setStringList("uuids", uuids);
                                });
                              }
                            }),
                      ),
                      maxLength: 36,
                    ),
                  ),
                  ListTile(
                    title: Text(
                      controller == null ? "Scan Beacons" : "Stop Scanning",
                    ),
                    onTap: manageButton,
                  ),
                  // TODO: Create seperate files for each seperate feature
                  // ListTile(
                  //   title: Text(
                  //     "Listen to radius",
                  //   ),
                  //   onTap: () {
                  //     snowmScanner
                  //         .getDistanceStream(0, 0) // what are the values?
                  //         .listen((double calculatedRadius) {
                  //       this.radius = calculatedRadius;
                  //     });
                  //   },
                  // ),
                  // ListTile(
                  //   title: Text("Background Scanning"),
                  //   onTap: backgroundScanning,
                  // ),
                  // if (id != null)
                  //   ListTile(
                  //     title: Text("Stop background scanning"),
                  //     onTap: stopBackgroundScanning,
                  //   ),
                  // ListTile(
                  //   onTap: () async {
                  //     await snowmScanner.startTransmitting(SnowMBeacon()
                  //       ..uuid = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"
                  //       ..major = 1
                  //       ..minor = 2
                  //       ..txPower = -20);
                  //     check();
                  //   },
                  //   title: Text('Start Transmiting'),
                  // ),
                  if (isTransmitting)
                    ListTile(
                      onTap: () async {
                        await snowmScanner.stopTransmitting();
                        await check();
                      },
                      title: Text('Stop Transmiting'),
                    ),
                  for (SnowMBeacon beacon in scannedBeacons)
                    BeaconTile(beacon: beacon)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  check() async {
    var a = await snowmScanner.isTransmitting();
    print(a);
    setState(() {
      isTransmitting = a!;
    });
  }

  void stopBackgroundScanning() async {
    await snowmScanner.stopBackgroudScan();
    initAsync();
  }
}

class BeaconTile extends StatelessWidget {
  const BeaconTile({
    Key? key,
    @required this.beacon,
  }) : super(key: key);

  final SnowMBeacon? beacon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.bluetooth_searching),
      title: Text("UUID:" + beacon!.uuid!),
      subtitle: Text("MAC address:" +
          beacon!.macAddress! +
          "\n" +
          "Distance:" +
          beacon!.distance!.toStringAsFixed(2) +
          "\n" +
          "Major/Minor:" +
          beacon!.major.toString() +
          "/" +
          "Detected At:" +
          DateFormat("HH:mm:ss").format(
              DateTime.fromMillisecondsSinceEpoch(beacon!.detectedTime)) +
          "/" +
          beacon!.minor.toString() +
          "\ntxPower:" +
          beacon!.txPower.toString() +
          "\n" +
          "rssi:" +
          beacon!.rssi.toString()),
      trailing: IconButton(
          icon: Icon(Icons.content_copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: beacon!.uuid!));
          }),
      isThreeLine: true,
    );
  }
}
