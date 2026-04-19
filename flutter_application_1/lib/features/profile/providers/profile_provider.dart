import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider((ref) => ProfileService());

/// One-shot read — kept for backwards compatibility with screens that only
/// need a snapshot. Prefer [providerStreamProvider] for views that should
/// react to aggregate (rating / reviewCount) updates.
final providerDataProvider =
    FutureProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
  (ref, uid) => ref.watch(profileServiceProvider).getProviderData(uid),
);

final merchantDataProvider =
    FutureProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
  (ref, uid) => ref.watch(profileServiceProvider).getMerchantData(uid),
);

/// Live provider-doc stream — updates whenever reviews recompute the
/// aggregate or the provider edits their profile.
final providerStreamProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
  (ref, uid) => ref.watch(profileServiceProvider).providerStream(uid),
);
