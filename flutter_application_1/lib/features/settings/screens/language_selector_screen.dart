import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class LanguageSelectorScreen extends StatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  State<LanguageSelectorScreen> createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends State<LanguageSelectorScreen> {
  String _selectedLang = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Language'), elevation: 0),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            _langTile('English', 'US'),
            _langTile('Français', 'FR'),
            _langTile('العربية', 'TN'),
          ],
        ),
      ),
    );
  }

  Widget _langTile(String name, String code) {
    final isSelected = _selectedLang == name;
    return ListTile(
      onTap: () => setState(() => _selectedLang = name),
      title: Text(name, style: AppTextStyles.bodyLarge),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.accentBlue) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? AppColors.accentBlue.withValues(alpha: 0.05) : null,
    );
  }
}
