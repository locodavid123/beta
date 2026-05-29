import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/creation.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter simulation history
    List<Creation> filteredCreations = state.creations.where((creation) {
      final matchesSearch = creation.petName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          creation.styleName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          creation.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final tabIndex = _tabController.index;
      final now = DateTime.now();
      if (tabIndex == 0) return matchesSearch; // Todos
      if (tabIndex == 1) {
        // Hoy
        return matchesSearch && now.difference(creation.date).inDays == 0;
      }
      if (tabIndex == 2) {
        // Esta semana
        return matchesSearch && now.difference(creation.date).inDays <= 7;
      }
      if (tabIndex == 3) {
        // Este mes
        return matchesSearch && now.difference(creation.date).inDays <= 30;
      }
      return matchesSearch;
    }).toList();

    // Stats calculations
    final totalSimulationsCount = 838 + state.creations.length;
    final weeklySimulationsCount = 43 + state.creations.where((c) => DateTime.now().difference(c.date).inDays <= 7).length;
    final distinctStylesCount = state.creations.map((c) => c.styleId).toSet().length + 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial Global', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Total simulations totals banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Text(
                    '$totalSimulationsCount simulaciones totales',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$weeklySimulationsCount esta semana  •  $distinctStylesCount estilos distintos',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por usuario o estilo...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Todos'),
                Tab(text: 'Hoy'),
                Tab(text: 'Semana'),
                Tab(text: 'Mes'),
              ],
            ),
          ),

          // History records list
          Expanded(
            child: filteredCreations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No hay registros para este filtro.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: filteredCreations.length,
                    itemBuilder: (context, index) {
                      final creation = filteredCreations[index];
                      return _buildHistoryCard(context, creation, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Creation creation, bool isDark) {
    // Generate simulated user names / initials
    final List<String> mockEmails = [
      'cliente_prueba',
      'maria.g',
      'carlos.p',
      'laura.m',
      'juan.r',
      'sofia.v',
    ];
    final userEmailPrefix = mockEmails[creation.likes % mockEmails.length];
    final userInitial = userEmailPrefix[0].toUpperCase();

    // Alternate success status
    final isSuccess = creation.likes % 10 != 0; // 90% success

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? AppTheme.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // User Avatar bubble
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // User & creation info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userEmailPrefix,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${creation.styleName}  •  ${creation.petName}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(creation.date),
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                ],
              ),
            ),

            // Status Badge (OK / Error)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isSuccess ? AppTheme.greenAccent : AppTheme.redAccent).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isSuccess ? 'OK' : 'Error',
                style: TextStyle(
                  color: isSuccess ? AppTheme.greenAccent : AppTheme.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
