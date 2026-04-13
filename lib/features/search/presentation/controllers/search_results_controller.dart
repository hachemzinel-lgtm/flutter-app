import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/providers/auth_providers.dart';
import '../../data/models/search_params.dart';
import '../../data/repositories/search_repository.dart';

final searchRepositoryProvider = Provider((ref) => SearchRepository());

final searchResultsProvider =
    FutureProvider.family<List<SearchResultItem>, SearchParams>((
      ref,
      params,
    ) async {
      final userDoc = await ref.watch(currentUserDocProvider.future);
      final userData = await ref.watch(currentUserDataProvider.future);

      if (userDoc == null || userDoc.location == null || userData == null) {
        throw Exception(
          'Missing user location or account type. Please update your profile.',
        );
      }

      return ref
          .watch(searchRepositoryProvider)
          .search(
            params,
            userLocation: userDoc.location!,
            currentAccountType: userData['accountType']?.toString() ?? 'client',
            currentUid: userDoc.uid,
          );
    });
