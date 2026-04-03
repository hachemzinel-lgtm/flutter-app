import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../services/review_service.dart';
import '../../auth/providers/auth_provider.dart';

class RateServiceScreen extends ConsumerStatefulWidget {
  const RateServiceScreen({super.key, required this.providerId});

  final String providerId;

  @override
  ConsumerState<RateServiceScreen> createState() => _RateServiceScreenState();
}

class _RateServiceScreenState extends ConsumerState<RateServiceScreen> {
  final _reviewController = TextEditingController();
  double _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a star rating first.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final authUser = ref.read(authServiceProvider).currentUser;
      final userDoc = ref.read(currentUserDocProvider).value;
      if (authUser == null || userDoc == null) {
        throw Exception('You must be signed in to leave a review.');
      }

      await ReviewService().submitReview(
        targetUserId: widget.providerId,
        reviewerId: authUser.uid,
        reviewerName: userDoc.name,
        reviewerPhoto: userDoc.photoUrl ?? '',
        rating: _rating,
        text: _reviewController.text.trim(),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for sharing your experience.'),
          backgroundColor: AppColors.availableGreen,
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserDocProvider).value;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .get(),
      builder: (context, snapshot) {
        final targetData = snapshot.data?.data();
        final targetName =
            targetData?['businessName']?.toString().trim().isNotEmpty == true
            ? targetData!['businessName'].toString()
            : targetData?['name']?.toString() ?? 'this user';
        final targetType = UserModel.parseUserType(
          targetData?['accountType']?.toString() ??
              targetData?['userType']?.toString() ??
              'client',
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Rate your experience')),
          body: currentUser != null && currentUser.userType != UserType.client
              ? Center(
                  child: Padding(
                    padding: AppSpacing.pagePadding,
                    child: Text(
                      'Only clients can submit reviews in NearWork.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'How was your experience with $targetName?',
                        style: AppTextStyles.headingMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        targetType == UserType.marketplace
                            ? 'Rate this marketplace and leave an optional review.'
                            : 'Rate this work provider and leave an optional review.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final value = index + 1.0;
                          return IconButton(
                            onPressed: () => setState(() => _rating = value),
                            iconSize: 42,
                            icon: Icon(
                              value <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.starGold,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: _reviewController,
                        maxLines: 6,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText:
                              'Tell others what went well or what could improve.',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Submit Review'),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
