part of stratosfy_scanner;

/// Enum to represent the state of the bluetooth on the device
enum BluetoothState {
  /// Unable to determine the state
  UNKNOWN,

  /// On state
  ON,

  /// Off state
  OFF,
}

BluetoothState _getBluetoothStateFromKey(String? key) {
  switch (key) {
    case "on":
      return BluetoothState.ON;
    case "off":
      return BluetoothState.OFF;
    default:
      return BluetoothState.UNKNOWN;
  }
}

/// Enum to represent the permission state of bluetooth for the application

enum BluetoothPermissionState {
  /// [authorizedAlways] in iOS and [granted] on Android
  GRANTED,

  /// [iOS only]
  WHENINUSE,

  /// Denied state
  DENIED,

  /// Unable to determine the state
  UNKNOWN,
}

BluetoothPermissionState _getBluetoothPermissionStateFromKey(String? key) {
  switch (key) {
    case "granted":
      return BluetoothPermissionState.GRANTED;
    case "whenInUse":
      return BluetoothPermissionState.WHENINUSE;
    case "denied":
      return BluetoothPermissionState.DENIED;
    default:
      return BluetoothPermissionState.UNKNOWN;
  }
}
