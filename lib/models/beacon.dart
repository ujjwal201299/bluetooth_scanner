part of stratosfy_scanner;

class SnowMBeacon {
  String? uuid, macAddress;
  int? major, minor, txPower, rssi;
  double? distance;
  late int detectedTime;

  static SnowMBeacon _fromMap(Map data) {
    return SnowMBeacon()
      ..uuid = data["uuid"]
      ..rssi = data["rssi"]
      ..major = data["major"]
      ..minor = data["minor"]
      ..txPower = data["txPower"]
      ..detectedTime = DateTime.now().millisecondsSinceEpoch
      ..macAddress = data["macAddress"]
      ..distance = data["distance"];
  }

  toMap() {
    return {
      "uuid": uuid,
      "major": major,
      "minor": minor,
      "txPower": txPower,
    };
  }
}
