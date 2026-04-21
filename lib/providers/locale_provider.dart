import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/providers/auth_provider.dart';

final appLocaleProvider = Provider<Locale?>((ref) {
  final code = ref.watch(currentUserDocProvider).value?.language;
  if (code == null || code.isEmpty) {
    return null;
  }

  return Locale(code);
});
