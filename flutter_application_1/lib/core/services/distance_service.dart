import 'dart:math' show cos, sqrt, asin;

class DistanceService {
  static final DistanceService _instance = DistanceService._internal();
  factory DistanceService() => _instance;
  DistanceService._internal();

  /// Calculates the distance between two geographical points using the Haversine formula.
  /// Returns distance in kilometers.
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Sorts a list of worker profile maps by distance from a given point (origin).
  List<Map<String, dynamic>> sortWorkersByDistance(
    List<Map<String, dynamic>> workers,
    double originLat,
    double originLng,
  ) {
    var sortedList = List<Map<String, dynamic>>.from(workers);
    sortedList.sort((a, b) {
      final aLat = (a['lat'] as num?)?.toDouble() ?? 0.0;
      final aLng = (a['lng'] as num?)?.toDouble() ?? 0.0;
      final bLat = (b['lat'] as num?)?.toDouble() ?? 0.0;
      final bLng = (b['lng'] as num?)?.toDouble() ?? 0.0;
      
      final distA = calculateDistance(originLat, originLng, aLat, aLng);
      final distB = calculateDistance(originLat, originLng, bLat, bLng);
      
      return distA.compareTo(distB);
    });
    return sortedList;
  }
}
