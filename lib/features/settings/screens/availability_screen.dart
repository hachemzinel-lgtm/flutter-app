import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Status'), elevation: 0),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: _isAvailable ? AppColors.availableGreen.withOpacity(0.1) : AppColors.softGray.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              ),
              child: Column(
                children: [
                  Icon(
                    _isAvailable ? Icons.check_circle_outline : Icons.pause_circle_outline,
                    size: 80,
                    color: _isAvailable ? AppColors.availableGreen : AppColors.softGray,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    _isAvailable ? 'You are Available' : 'You are Offline',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: _isAvailable ? AppColors.availableGreen : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    _isAvailable 
                      ? 'Customers can see you on the map and send requests.'
                      : 'You are hidden from the map and won\'t receive new alerts.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const Spacer(),
            PrimaryButton(
              text: _isAvailable ? 'Go Offline' : 'Go Online',
              onPressed: () => setState(() => _isAvailable = !_isAvailable),
            ),
          ],
        ),
      ),
    );
  }
}
