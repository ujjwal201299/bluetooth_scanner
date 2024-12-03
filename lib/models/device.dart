part of stratosfy_scanner;

class StratosfyDevice {
  StratosfyDevice({
    this.companyId,
    this.macAddress,
    this.battery,
    this.rawPacket,
    this.packetId,
    this.firmwareVersion,
    this.iBeaconUUID,
    this.hardwareId,
    this.productSolutionId,
    this.airTemperatureRaw,
    this.surfaceTemperatureRaw,
    this.serialNo,
  });

  String? companyId;
  String? macAddress;
  int? battery;
  String? rawPacket;
  String? packetId;
  String? iBeaconUUID;
  String? firmwareVersion;
  String? hardwareId;
  String? productSolutionId;
  String? airTemperatureRaw;
  String? surfaceTemperatureRaw;
  String? serialNo;

  static StratosfyDevice _parse(Map args) {
    String rawData = args["rawData"];

    String macAddress = _getMacFromRAW(rawData);

    return StratosfyDevice(
      rawPacket: rawData,
      battery: _canHaveBattery(rawData)
          ? _convertHexToDecimal(_getBattery(rawData))
          : null,
      companyId: rawData.substring(10, 14),
      macAddress: _getMacFromRAW(rawData),
      packetId: rawData.substring(26, 28),
      iBeaconUUID: _getHyphedUUID(asciiToHex(_getUUIDFromMac(macAddress))),
      firmwareVersion: _parseFirmwareVersion(rawData),
      hardwareId: rawData.substring(34, 36),
      productSolutionId: rawData.substring(36, 38),
      airTemperatureRaw: rawData.substring(40, 44),
      surfaceTemperatureRaw: rawData.substring(44, 48),
      serialNo: rawData.substring(48),
    );
  }

  factory StratosfyDevice.fromMap(Map<String, dynamic> json) => StratosfyDevice(
        companyId: json["companyId"] == null ? null : json["companyId"],
        macAddress: (json["macAddress"]),
        battery: json["battery"] == null ? null : json["battery"],
        rawPacket: json["rawPacket"] == null ? null : json["rawPacket"],
        iBeaconUUID: json["iBeaconUUID"] == null ? null : json["iBeaconUUID"],
        packetId: json["packetId"] == null ? null : json["packetId"],
        firmwareVersion:
            json["firmwareVersion"] == null ? null : json["firmwareVersion"],
        hardwareId: json["hardwareId"] == null ? null : json["hardwareId"],
        productSolutionId: json["productSolutionId"] == null
            ? null
            : json["productSolutionId"],
        airTemperatureRaw: json["airTemperatureRaw"] == null
            ? null
            : json["airTemperatureRaw"],
        surfaceTemperatureRaw: json["surfaceTemperatureRaw"] == null
            ? null
            : json["surfaceTemperatureRaw"],
        serialNo: json["serialNo"] == null ? null : json["serialNo"],
      );

  Map<String, dynamic> toMap() => {
        "companyId": companyId == null ? null : companyId,
        "macAddress": macAddress == null ? null : macAddress,
        "battery": battery == null ? null : battery,
        "rawPacket": rawPacket == null ? null : rawPacket,
        "packetId": packetId == null ? null : packetId,
        "firmwareVersion": firmwareVersion == null ? null : firmwareVersion,
        "iBeaconUUID": iBeaconUUID == null ? null : iBeaconUUID,
        "hardwareId": hardwareId == null ? null : hardwareId,
        "productSolutionId":
            productSolutionId == null ? null : productSolutionId,
        "airTemperatureRaw":
            airTemperatureRaw == null ? null : airTemperatureRaw,
        "surfaceTemperatureRaw":
            surfaceTemperatureRaw == null ? null : surfaceTemperatureRaw,
        "serialNo": serialNo == null ? null : serialNo,
      };
}
