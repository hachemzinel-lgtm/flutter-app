import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider((ref) => ProfileService());

final providerDataProvider = FutureProvider.family((ref, String uid) {
  return ref.watch(profileServiceProvider).getProviderData(uid);
});

final merchantDataProvider = FutureProvider.family((ref, String uid) {
  return ref.watch(profileServiceProvider).getMerchantData(uid);
});
