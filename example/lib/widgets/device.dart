import 'package:flutter/material.dart';
import 'package:stratosfy_scanner/stratosfy_scanner.dart';

class StratosfyDeviceCard extends StatelessWidget {
  const StratosfyDeviceCard({Key? key, this.device}) : super(key: key);
  final StratosfyDevice? device;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text("Stratosfy Device"),
            subtitle: Text("Serial Number: " + device!.serialNo!),
            trailing: Text(device!.firmwareVersion!),
          ),
          ListTile(
            title: Text("iBeacon UUID"),
            dense: true,
            subtitle: SelectableText(device!.iBeaconUUID!),
          ),
          ListTile(
            title: Text("MAC Address"),
            dense: true,
            trailing: SelectableText(device!.macAddress!),
          ),
          ListTile(
            title: Text("Battery"),
            dense: true,
            trailing: Text("${device!.battery ?? "-"} %"),
          ),
          ListTile(
            title: Text("Packet ID"),
            dense: true,
            trailing: Text("${device!.packetId ?? "-"}"),
          ),
          ListTile(
            title: Text("Hardware ID"),
            dense: true,
            trailing: Text("${device!.hardwareId ?? "-"}"),
          ),
          ListTile(
            title: Text("Product ID"),
            dense: true,
            trailing: Text("${device!.productSolutionId ?? "-"}"),
          ),
          ListTile(
            title: Text("Air Temperature"),
            dense: true,
            trailing: Text("${device!.airTemperatureRaw ?? "-"}"),
          ),
          ListTile(
            title: Text("Surface Temperature"),
            dense: true,
            trailing: Text("${device!.airTemperatureRaw ?? "-"}"),
          ),
          ListTile(
            title: Text("Raw Packet"),
            dense: true,
            subtitle: SelectableText(device!.rawPacket!),
          ),
        ],
      ),
    );
  }
}
