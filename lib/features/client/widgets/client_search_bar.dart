import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ClientSearchBar extends StatefulWidget {
  final String? initialQuery;
  final String initialTarget; // 'work_provider' or 'marketplace'

  const ClientSearchBar({
    super.key,
    this.initialQuery,
    this.initialTarget = 'work_provider',
  });

  @override
  State<ClientSearchBar> createState() => _ClientSearchBarState();
}

class _ClientSearchBarState extends State<ClientSearchBar> {
  late final TextEditingController _controller;
  late String _currentTarget;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Plumber', 'icon': Icons.plumbing},
    {'label': 'Electrician', 'icon': Icons.electrical_services},
    {'label': 'Cleaner', 'icon': Icons.cleaning_services},
    {'label': 'Carpenter', 'icon': Icons.handyman},
    {'label': 'Painter', 'icon': Icons.format_paint},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _currentTarget = widget.initialTarget;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _controller.text.trim();
    context.push('/search-results?query=$query&target=$_currentTarget');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input field
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.softGray),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _onSearch(),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search for ${_currentTarget == 'work_provider' ? 'experts' : 'products'}...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _onSearch,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward, size: 20, color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Target Selector (WP vs Marketplace)
        Row(
          children: [
            _targetChip('Work Providers', 'work_provider'),
            const SizedBox(width: 8),
            _targetChip('Marketplace', 'marketplace'),
          ],
        ),
        const SizedBox(height: 16),
        // Category Chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(cat['icon'], size: 16, color: AppColors.accentBlue),
                  label: Text(cat['label'], style: AppTextStyles.labelSmall),
                  backgroundColor: AppColors.white,
                  side: BorderSide(color: AppColors.softGray.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    context.push('/search-results?category=${cat['label']}&target=$_currentTarget');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _targetChip(String label, String value) {
    final isSelected = _currentTarget == value;
    return GestureDetector(
      onTap: () => setState(() => _currentTarget = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.softGray.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
