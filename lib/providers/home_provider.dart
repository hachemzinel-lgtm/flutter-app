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
  try {
    final user = ref.watch(currentUserDocProvider).asData?.value;
    return ref
        .read(discoveryServiceProvider)
        .topRatedProviders(
          savedLocation: user?.location,
          savedAddress: user?.address,
        );
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(error, stackTrace);
  }
});

final searchResultsProvider = FutureProvider.family
    .autoDispose<List<DiscoverySearchResult>, DiscoverySearchRequest>((
      ref,
      request,
    ) async {
      try {
        return ref.read(discoveryServiceProvider).search(request);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    });

final selectedRadiusProvider = StateProvider<double>((ref) => 10);
final selectedMinimumRatingProvider = StateProvider<double>((ref) => 0);
final availableOnlyProvider = StateProvider<bool>((ref) => false);
final useCurrentLocationProvider = StateProvider<bool>((ref) => true);
final manualSearchAddressProvider = StateProvider<String>((ref) => '');

final providersStreamProvider = StreamProvider.family
    .autoDispose<List<DiscoverySearchResult>, DiscoverySearchType>((ref, type) {
      final stream = ref
          .read(discoveryServiceProvider)
          .streamProviders(type: type);
      return (() async* {
        try {
          await for (final results in stream) {
            yield results;
          }
        } catch (error, stackTrace) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      })();
    });
