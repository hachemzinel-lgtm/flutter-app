import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailabilityNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> toggle(bool val) async {
    state = val;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isAvailableNow': val});
  }
}

final availabilityProvider = NotifierProvider<AvailabilityNotifier, bool>(AvailabilityNotifier.new);
