// ignore_for_file: unnecessary_null_comparison

part of stratosfy_scanner;

class _SnowMScanner {
  static const MethodChannel _channel = const MethodChannel('snowm_scanner');
  int _ibeaconScannerCount = 0;
  int _stateScannerCount = 0;
  Map<String, StreamController<List<SnowMBeacon>?>> _ibeaconStreamPool = {};
  Map<String, StreamController<BluetoothState>> _stateStreamPool = {};
  Map<String, Map<String, SnowMBeacon>> _cachedIBeacons = {};
  StreamController<StratosfyDevice> telemetryPacketStream = StreamController();
  bool _enableMqtt = false;
  int _timeInterval = 600000;

  _SnowMScanner() {
    print("_SnowMScanner called, ${_channel.name}");
    _channel.setMethodCallHandler((call) async {
      String method = call.method;
      print('${method}, method123');
      if (method.contains("scanIBeacons") &&
          _ibeaconStreamPool.containsKey(call.method)) {
        List<SnowMBeacon>? beacons = call.arguments["beacons"]
            .map<SnowMBeacon>((b) => SnowMBeacon._fromMap(b))
            .toList();
        _ibeaconStreamPool[call.method]!.add(beacons);
      } else if (method.contains("bluetoothStateListener")) {
        _stateStreamPool[call.method]!
            .add(_getBluetoothStateFromKey(call.arguments));
      } else if (method.contains("scanTelemetryBeacons")) {
        print("cddfdf");
        telemetryPacketStream.add(StratosfyDevice._parse(call.arguments));
      }
      return;
      // } as Future<dynamic> Function(MethodCall)?);
    });
  }

  Future<bool> println() async {
    return false;
  }

  /// [Optional] Configuration for the scanner
  void configure({
    /// Should scanner send messages to mqtt protocol. Default [false]
    bool enableMqtt = false,

    /// Time interval[Milliseconds] to send data to IOT cloud.Default is 10 minutes
    /// Valid only if [enableMqtt] is true.
    int timeInterval = 600000,
  }) {
    assert(timeInterval >= 60000);
    this._enableMqtt = enableMqtt;
    this._timeInterval = timeInterval;
  }

  /// Stream which splits the bluetooth adapter state
  Stream<BluetoothState?> getBluetoothStateStream() {
    String method = "bluetoothStateListener#${++_stateScannerCount}";
    _stateStreamPool[method] =
        _getNewBluetoothStateStreamController<BluetoothState>(method);
    _channel.invokeMethod(method);
    return _stateStreamPool[method]!.stream;
  }

  /// Retrives the permission state of the scanner
  Future<BluetoothPermissionState> getPermissionState() async {
    return _getBluetoothPermissionStateFromKey(
        await _channel.invokeMethod<String>("permissionState"));
  }

  /// Asks for location permission from the platfrom
  void requestPermission() {
    _channel.invokeMethod<String>("requestPermission");
  }

  /// Registers a geofence in the backend
  Future<void> registerGeofence(Geofence geofence) {
    return _channel.invokeMethod<bool>(
      "geofence#register",
      geofence.toMap(),
    );
  }

  Future<void> removeGeofence(String identifier) {
    return _channel
        .invokeMethod<bool>("geofence#remove", {"identifier": identifier});
  }

  Future<bool?> removeAllGeofence() {
    return _channel.invokeMethod<bool>("geofence#removeAll");
  }

  /// Retrives the hardware state of the bluetooth adapter on the device.
  Future<BluetoothState> getBluetoothState() async {
    return _getBluetoothStateFromKey(
        await _channel.invokeMethod<String>("bluetoothState"));
  }

  /// Starts a background scanning session and sends the response to the native side.
  /// [scanId] cannot be a `null` value
  /// [uuids] must have atleast one uuid
  Future<void> scanIBeaconsInBackground(
      String scanId,

      /// List of UUIDs that the scanner session should scan.
      List<String> uuids,
      {
      /// [Android] Title of the foreground scanner notification title
      String title = "SnowM Scanner",

      /// [Android] Title of the foreground scanner notification body
      String body = "We are scanning beacons currently.",

      /// Geofence parameters, if this is passed the scanner will only scan when the user gets inside the geofence.
      List<Geofence> geofences = const [],

      /// Custom payload that can be sent to scanner which will be delivered along with the scanned beacons
      Map<String, dynamic> customData = const {},

      /// [only Android] Time interval in milliseconds to scan beacons.Default is 5 seconds
      int backgroundScanPeriod = 5000,

      /// [only Android] Time interval in milliseconds to wait between scans.Default is 10 seconds
      int backgroundBetweenScanPeriod = 10000,

      /// [only IOS] prefix to be added to beacon region uuid+prefix
      String identifierPrefix = ""}) async {
    assert(scanId != null);
    assert(uuids.length > 0);
    if (await getCurrentScanId() != null) {
      await stopBackgroudScan();
    }
    await _channel.invokeMethod('scanIBeaconBackground', {
      "scanId": scanId,
      "uuids": uuids.map((e) => e.toUpperCase()).toList(),
      "geofences": geofences.map((e) => e.toMap()).toList(),
      "customData": customData,
      "title": title,
      "body": body,
      "identifierPrefix": identifierPrefix,
      "backgroundScanPeriod": backgroundScanPeriod,
      "backgroundBetweenScanPeriod": backgroundBetweenScanPeriod
    });
  }

  /// Get the active scanning session id, if no background scanner is active it will return `null`
  Future<String?> getCurrentScanId() async {
    return _channel.invokeMethod('getCurrentScanId');
  }

  /// Stops background scanning, the scanner should have been registered in order to stop it.
  Future<void> stopBackgroudScan() async {
    await _channel.invokeMethod('stopBackgroundScan');
  }

  /// Scans and sends the scan response on the foreground ie Dart side
  /// [uuids] must have atleast one uuid
  Stream<List<SnowMBeacon>> scanIBeacons(
      {
      /// List of proximity uuid of a beacon to be scanned
      List<String>? uuids,

      /// Milliseconds for which the beacons should be cached. Default value is 60 seconds.
      int cacheBeaconsFor = 10000,

      /// [Android only] Scan and return all beacons in range, default value is `false`
      bool scanAllIBeacons = false}) async* {
    if (!Platform.isAndroid) assert(scanAllIBeacons == false);
    bool granted = await permissionHandler.requestLocationPermission();
    if (!granted) {
      throw Exception("You must allow device scan permission to continue");
    }
    String method = "scanIBeacons#${++_ibeaconScannerCount}";
    _ibeaconStreamPool[method] =
        _getNewIBeaconStreamController<List<SnowMBeacon>?>(method);
    _channel.invokeMethod(method, {
      "uuids": uuids != null ? uuids.map((e) => e.toUpperCase()).toList() : [],
      "enableMqtt": _enableMqtt,
      "timeInterval": _timeInterval,
      "scanAllIBeacons": scanAllIBeacons
    });
    Map<String?, SnowMBeacon> cachedIBeacons = _cachedIBeacons[method] ?? {};
    yield* _ibeaconStreamPool[method]!.stream.map((beacons) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      beacons = beacons!.map((e) {
        e..detectedTime = currentTime;
        cachedIBeacons[e.uuid] = e;
        return e;
      }).toList();
      List<SnowMBeacon> freshIBeacons = cachedIBeacons.values
          .where((b) => (currentTime - b.detectedTime) < cacheBeaconsFor)
          .toList();
      cachedIBeacons.clear();
      freshIBeacons.forEach((b) {
        cachedIBeacons[b.uuid] = b;
      });
      return freshIBeacons;
    });
  }

  Future<Stream<StratosfyDevice>> scanTelemetry(
      {bool syncWithSever = false}) async {
    bool granted = await permissionHandler.requestLocationPermission();
    if (!granted) {
      throw Exception("You must allow device scan permission to continue");
    }

    _channel.invokeMethod('scanTelemetryBeacons', {
      "syncWithServer": syncWithSever,
    });
    telemetryPacketStream.onCancel = () {
      stopScanningTelemetry();
    };
    return telemetryPacketStream.stream;
  }

  Future stopScanningTelemetry() async {
    telemetryPacketStream.close();
    telemetryPacketStream = StreamController();
    return await _channel.invokeMethod('stopScanningTelemetry');
  }

  StreamController<T> _getNewIBeaconStreamController<T>(String identifier) {
    StreamController<T> controller = StreamController<T>();
    controller.onCancel = () {
      _channel.invokeMethod("cancelStream", {
        "methodName": identifier,
      });
      _ibeaconStreamPool.remove(identifier);
    };
    return controller;
  }

  StreamController<T> _getNewBluetoothStateStreamController<T>(
      String identifier) {
    StreamController<T> controller = StreamController<T>();
    controller.onCancel = () {
      _channel.invokeMethod("cancelBluetoothStateListener", {
        "methodName": identifier,
      });
      _ibeaconStreamPool.remove(identifier);
    };
    return controller;
  }

  /// [Android] Start transmitting `SnowMBeacon`,
  /// This method is Only supported for  `Android 5.0+`
  Future<void> startTransmitting(SnowMBeacon snowMBeacon) async {
    if (Platform.isAndroid)
      await _channel.invokeMethod('transmitIBeacon', snowMBeacon.toMap());
    else
      throw Exception(
          "UnsupportedAction:This task is only supported on android 5+");
  }

  /// Stops the beacon transmission.
  /// Call only when beacon transmission is going on,
  /// To check if transmitting or not use `isTransmitting` method
  Future<void> stopTransmitting() async {
    await _channel.invokeMethod('stopTransmission');
  }

  /// Returns `true` if transmitting beacon else `false`
  Future<bool?> isTransmitting() async {
    return await _channel.invokeMethod("checkTransmission");
  }

  ///
  Stream<double> getDistanceStream(double latitude, double longitude) {
    return _getDistanceStream(latitude, longitude);
  }
}

/// Entry point for the scanner to scan beacons
final snowmScanner = _SnowMScanner();
