import 'package:flutter/material.dart';
import 'package:stratosfy_scanner/stratosfy_scanner.dart';

class BluetoothStatus extends StatefulWidget {
  @override
  _BluetoothStatusState createState() => _BluetoothStatusState();
}

class _BluetoothStatusState extends State<BluetoothStatus> {
  BluetoothState? status;
  @override
  void initState() {
    super.initState();
    snowmScanner.getBluetoothStateStream().listen((event) {
      setState(() {
        status = event;
      });
    });
  }

  String get bluetoothStatus {
    if (status == null || status == BluetoothState.UNKNOWN)
      return "-";
    else if (status == BluetoothState.OFF)
      return "Turned Off";
    else
      return "Turned On";
  }

  Color get color {
    if (status == null || status == BluetoothState.UNKNOWN)
      return Colors.grey;
    else if (status == BluetoothState.OFF)
      return Colors.red;
    else
      return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: ListTile(
        title: Text("Bluetooth Status"),
        trailing: Text(bluetoothStatus),
      ),
    );
  }
}
