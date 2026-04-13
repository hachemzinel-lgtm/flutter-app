import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/verification_result.dart';
import '../../data/repositories/document_verification_repository.dart';

enum VerificationStateStatus { idle, loading, success, failure }

class VerificationState {
  final VerificationStateStatus status;
  final DocumentVerificationResult? result;
  final String? error;

  const VerificationState({
    required this.status,
    this.result,
    this.error,
  });

  factory VerificationState.idle() =>
      const VerificationState(status: VerificationStateStatus.idle);
  factory VerificationState.loading() =>
      const VerificationState(status: VerificationStateStatus.loading);
  factory VerificationState.success(DocumentVerificationResult result) =>
      VerificationState(status: VerificationStateStatus.success, result: result);
  factory VerificationState.failure(String error) =>
      VerificationState(status: VerificationStateStatus.failure, error: error);
}

final documentVerificationRepositoryProvider =
    Provider<DocumentVerificationRepository>(
        (ref) => DocumentVerificationRepository());

final verificationControllerProvider =
    NotifierProvider<VerificationController, VerificationState>(
  VerificationController.new,
);

class VerificationController extends Notifier<VerificationState> {
  @override
  VerificationState build() => VerificationState.idle();

  DocumentVerificationRepository get _repository =>
      ref.read(documentVerificationRepositoryProvider);

  void reset() {
    state = VerificationState.idle();
  }

  Future<void> verifyDocument(File imageFile, String uid) async {
    state = VerificationState.loading();
    try {
      final result = await _repository.verifyDocument(
        imageFile: imageFile,
        uid: uid,
      );

      if (result.isVerified) {
        state = VerificationState.success(result);
      } else {
        state = VerificationState.failure(result.reason);
      }
    } catch (e) {
      state = VerificationState.failure('An unexpected error occurred: $e');
    }
  }
}
