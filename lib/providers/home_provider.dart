import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/models/discovery_models.dart';
import 'package:flutter_application_1/services/discovery_service.dart';

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return DiscoveryService();
});

final topRatedProvidersProvider = FutureProvider<List<DiscoverySearchResult>>((
  ref,
) async {
  final user = ref.watch(currentUserDocProvider).value;
  return ref
      .read(discoveryServiceProvider)
      .topRatedProviders(
        savedLocation: user?.location,
        savedAddress: user?.address,
      );
});

final searchResultsProvider = FutureProvider.family
    .autoDispose<List<DiscoverySearchResult>, DiscoverySearchRequest>((
      ref,
      request,
    ) async {
      return ref.read(discoveryServiceProvider).search(request);
    });

final selectedRadiusProvider = StateProvider<double>((ref) => 10);
final selectedMinimumRatingProvider = StateProvider<double>((ref) => 0);
final availableOnlyProvider = StateProvider<bool>((ref) => false);
final useCurrentLocationProvider = StateProvider<bool>((ref) => true);
final manualSearchAddressProvider = StateProvider<String>((ref) => '');

final providersStreamProvider = StreamProvider.family
    .autoDispose<List<DiscoverySearchResult>, DiscoverySearchType>((ref, type) {
      return ref.read(discoveryServiceProvider).streamProviders(type: type);
    });
