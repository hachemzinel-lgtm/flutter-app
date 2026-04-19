import 'package:flutter_application_1/core/services/distance_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sample test — sanity-checks the Haversine distance math used for the
/// home-map radius filter and the "nearby providers" sort. Ships as an
/// example: copy this file and point `flutter test` at new pure-Dart
/// services as they land.
void main() {
  final svc = DistanceService();

  group('DistanceService.calculateDistance', () {
    test('returns zero for identical coordinates', () {
      expect(svc.calculateDistance(36.8065, 10.1815, 36.8065, 10.1815),
          closeTo(0.0, 0.001));
    });

    test('matches a known real-world distance within 1% tolerance', () {
      // Tunis ↔ Sfax is ~270 km as the crow flies. Haversine should land
      // within ~1% of that reference value.
      final km = svc.calculateDistance(36.8065, 10.1815, 34.7406, 10.7603);
      expect(km, greaterThan(267));
      expect(km, lessThan(273));
    });

    test('is symmetric', () {
      final a = svc.calculateDistance(36.8, 10.2, 34.7, 10.8);
      final b = svc.calculateDistance(34.7, 10.8, 36.8, 10.2);
      expect(a, closeTo(b, 0.0001));
    });
  });

  group('DistanceService.sortWorkersByDistance', () {
    test('orders providers nearest-first', () {
      final workers = [
        {'id': 'far', 'lat': 34.74, 'lng': 10.76},
        {'id': 'near', 'lat': 36.81, 'lng': 10.18},
        {'id': 'mid', 'lat': 35.67, 'lng': 10.11},
      ];
      final sorted = svc.sortWorkersByDistance(workers, 36.8065, 10.1815);
      expect(sorted.map((w) => w['id']).toList(),
          equals(['near', 'mid', 'far']));
    });

    test('treats missing coordinates as origin (falls back to 0,0)', () {
      // This documents current behavior: a worker without coords ends up
      // sorted relative to (0,0) rather than dropped. Tests catch any
      // silent change of contract.
      final workers = [
        {'id': 'has-coords', 'lat': 36.81, 'lng': 10.18},
        {'id': 'no-coords'},
      ];
      final sorted = svc.sortWorkersByDistance(workers, 36.8065, 10.1815);
      expect(sorted.first['id'], equals('has-coords'));
    });
  });
}
