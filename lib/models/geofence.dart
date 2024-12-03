part of stratosfy_scanner;

/// Object to represent the geofencing parameter
class Geofence {
  String identifier;
  double latitude, longitude;
  int radius;
  Map<String, dynamic> customData;
  Geofence({
    // Identifier for the geofencing, if you are sending geofencing to a background scanner, identifier is ignored
    required this.identifier,
    // Latitude of the geofence
    required this.latitude,
    // Longitude of the geofence
    required this.longitude,
    // Radius of the geofence, should be in meters and greater than 200
    required this.radius,
    // Custom payload that you want to attach to the geofence. It will be delivered on the native side with enter and exit events
    this.customData = const {},
  }) : assert(radius >= 200);

  Map toMap() {
    return {
      "identifier": identifier,
      "latitude": latitude,
      "longitude": longitude,
      "radius": radius,
      "customData": customData,
    };
  }
}
