import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/creation.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build filters list dynamically based on pets in history
    final petsInHistory = state.creations.map((c) => c.petName).toSet().toList();
    final filters = ['Todos', ...petsInHistory];

    // Filter creations
    final filteredCreations = state.creations.where((c) {
      return _selectedFilter == 'Todos' || c.petName == _selectedFilter;
    }).toList();

    // Calculations for summary card
    final totalCreated = state.creations.length;
    final distinctStyles = state.creations.map((c) => c.styleId).toSet().length;
    final distinctPets = state.creations.map((c) => c.petId).toSet().length;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.translate('history_title')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic summary purple card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.translate('history_created_count', params: {'count': totalCreated.toString()}),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.translate('history_summary_sub', params: {
                            'styles': distinctStyles.toString(),
                            'pets': distinctPets.toString(),
                          }),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filters list
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = _selectedFilter == filter;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      filter == 'Todos' ? state.translate('history_filter_all') : filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: isDark ? AppTheme.cardDark : const Color(0xFFEFEBFA),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // List of items
          Expanded(
            child: filteredCreations.isEmpty
                ? Center(
                    child: Text(
                      state.translate('history_no_creations'),
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredCreations.length,
                    itemBuilder: (context, index) {
                      final creation = filteredCreations[index];
                      return _buildCreationItem(context, creation, state);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationItem(BuildContext context, Creation creation, AppStateProvider state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('h:mm a').format(creation.date);
    final dayStr = _formatDay(creation.date, state);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: creation.imagePath.startsWith('assets/')
                  ? Image.asset(
                      creation.imagePath,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(creation.imagePath),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${creation.petName} • ${creation.styleName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dayStr, $dateStr • ❤️ ${creation.likes}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // "Generado con IA" Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.translate('history_badge_ia'),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.download, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.translate('history_saved_gallery'))),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.translate('history_link_copied'))),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDay(DateTime date, AppStateProvider state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return state.translate('history_day_today');
    } else if (checkDate == yesterday) {
      return state.translate('history_day_yesterday');
    } else {
      final localeCode = state.language == 'English'
          ? 'en'
          : state.language == 'Português'
              ? 'pt'
              : 'es';
      return DateFormat('d MMM', localeCode).format(date);
    }
  }
}
