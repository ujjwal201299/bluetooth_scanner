library stratosfy_scanner;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:stratosfy_scanner/scanner/permission.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

part "./models/beacon.dart";
part 'models/utils.dart';
part "./models/enums.dart";
part "./models/geofence.dart";
part "./models/device.dart";
part "./scanner/snowm.dart";
part "./scanner/geoservice.dart";
