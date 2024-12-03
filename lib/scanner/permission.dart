import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  Future<bool> requestLocationPermission() async {
    Map<Permission, PermissionStatus> status = await [
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.locationAlways,
      // Permission.nearbyWifiDevices,
      Permission.bluetooth,
    ].request();
    return status.values.every((e) => e == PermissionStatus.granted);
  }
}

final permissionHandler = PermissionHandler();
