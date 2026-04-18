import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/profile_card.dart';

class ResultsListScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  final String target; // 'work_provider' or 'marketplace'
  
  const ResultsListScreen({
    super.key, 
    this.initialQuery, 
    this.initialCategory,
    this.target = 'work_provider',
  });

  @override
  State<ResultsListScreen> createState() => _ResultsListScreenState();
}

class _ResultsListScreenState extends State<ResultsListScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  late String _query;
  String? _activeCategoryChip;
  late String _target;

  // Mock provider data
  final List<Map<String, dynamic>> _mockData = [
    {
      'name': 'Ahmed Ben Ali',
      'profession': 'Plumber',
      'type': 'work_provider',
      'rating': 4.9,
      'reviewCount': 87,
      'distanceKm': 1.2,
      'isAvailable': true,
    },
    {
      'name': 'Hardware Store Central',
      'profession': 'Tools & Supplies',
      'type': 'marketplace',
      'rating': 4.8,
      'reviewCount': 120,
      'distanceKm': 0.8,
      'isAvailable': true,
    },
    {
      'name': 'Khalil Mansour',
      'profession': 'Electrician',
      'type': 'work_provider',
      'rating': 4.7,
      'reviewCount': 53,
      'distanceKm': 2.8,
      'isAvailable': true,
    },
    {
      'name': 'Modern Paint Shop',
      'profession': 'Painting Supplies',
      'type': 'marketplace',
      'rating': 4.5,
      'reviewCount': 65,
      'distanceKm': 3.1,
      'isAvailable': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _query);
    _activeCategoryChip = widget.initialCategory;
    _target = widget.target;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim());
    });
  }

  List<Map<String, dynamic>> get _filtered {
    return _mockData.where((p) {
      final matchesTarget = p['type'] == _target;
      
      final matchesCategory = _activeCategoryChip == null || _activeCategoryChip == 'All' ||
          (p['profession'] as String).toLowerCase() == _activeCategoryChip!.toLowerCase();
          
      final q = _query.toLowerCase();
      final matchesText = q.isEmpty ||
          (p['name'] as String).toLowerCase().contains(q) ||
          (p['profession'] as String).toLowerCase().contains(q);
          
      return matchesTarget && matchesCategory && matchesText;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(_target == 'work_provider' ? 'Service Experts' : 'Marketplace', style: AppTextStyles.headingSmall),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search for ${_target == 'work_provider' ? 'experts' : 'products'}...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.softGray.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Search Results List
          Expanded(
            child: results.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final p = results[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ProfileCard(
                          name: p['name'],
                          profession: p['profession'],
                          rating: p['rating'],
                          reviewCount: p['reviewCount'],
                          isAvailable: p['isAvailable'],
                          heroTag: 'result_$index',
                          onTap: () {
                            final path = _target == 'work_provider' ? '/provider-profile' : '/merchant-profile';
                            context.push('$path/mock_$index');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.softGray.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No results found', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text('Try a different search or category', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
