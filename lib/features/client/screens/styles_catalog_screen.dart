import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/style.dart';

class StylesCatalogScreen extends StatefulWidget {
  const StylesCatalogScreen({super.key});

  @override
  State<StylesCatalogScreen> createState() => _StylesCatalogScreenState();
}

class _StylesCatalogScreenState extends State<StylesCatalogScreen> {
  String _selectedCategory = 'Todos';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'Todos',
    'Fantasía',
    'Arte',
    'Clásico',
    'Steampunk',
    'Sci-Fi',
    'Cute',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter styles based on category and search query
    final filteredStyles = state.styles.where((style) {
      final matchesCategory = _selectedCategory == 'Todos' || style.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = style.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          style.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Estilos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Buscar estilos...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: isDark ? AppTheme.cardDark : const Color(0xFFF4F0FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Categories horizontal scroll
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
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

          // Styles Grid
          Expanded(
            child: filteredStyles.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron estilos en esta categoría.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredStyles.length,
                    itemBuilder: (context, index) {
                      final style = filteredStyles[index];
                      return _buildStyleCard(context, style);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(BuildContext context, ArtStyle style) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = Provider.of<AppStateProvider>(context, listen: false);

    return Container(
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
      child: Stack(
        children: [
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Style Image
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.asset(
                    style.imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          style.category,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                        // Small arrow button
                        GestureDetector(
                          onTap: () {
                            // Navigate to simulator with style pre-selected
                            // We can push to the simulator tab
                            state.setNavIndex(2);
                            // We will save pre-selected style in state if desired, but we can do that in simulator using direct index / controller logic
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Hot Tag Badge
          if (style.isHot)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text(
                      'Hot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
