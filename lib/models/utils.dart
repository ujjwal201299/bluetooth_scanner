// ignore_for_file: unused_element

part of stratosfy_scanner;

String _hexStringtoAscii(String hexString) {
  List<String> splitted = [];
  for (int i = 0; i < hexString.length; i = i + 2) {
    splitted.add(hexString.substring(i, i + 2));
  }
  String ascii = List.generate(splitted.length,
      (i) => String.fromCharCode(int.parse(splitted[i], radix: 16))).join();

  return ascii;
}

String asciiToHex(String value) {
  return value.characters.map((e) => e.codeUnitAt(0).toRadixString(16)).join();
}

String _getBattery(String raw) {
  return raw.substring(38, 40);
}

int _convertHexToDecimal(String str) {
  return int.parse(str, radix: 16);
}

String _getUUIDFromMac(String mac) {
  return ("STSF" + mac).toUpperCase();
}

String _getMacFromRAW(String raw) {
  return raw.substring(14, 26).toUpperCase();
}

String? _parseFirmwareVersion(String raw) {
  String major = raw.substring(28, 30);
  String minor = raw.substring(30, 32);
  String revision = raw.substring(32, 34);
  try {
    int maj = int.parse(major);
    int min = int.parse(minor);
    int rev = int.parse(revision);
    return "$maj.$min.$rev";
  } catch (e) {
    return null;
  }
}

bool _canHaveBattery(String raw) {
  return _parseFirmwareVersion(raw)!.compareTo("1.3.0") >= 0;
}

String _getHyphedUUID(String uuid) {
  return "${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20, 32)}";
}
