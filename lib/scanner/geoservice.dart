part of stratosfy_scanner;

double _coordinateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos as double Function(num?);
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

Stream<double> _getDistanceStream(double latitude, double longitude) {
  return Geolocator.getPositionStream().map((position) {
    var radius = _coordinateDistance(
        longitude, latitude, position.longitude, position.latitude);
    return radius;
  });
}
