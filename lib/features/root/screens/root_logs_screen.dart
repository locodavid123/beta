import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RootLogsScreen extends StatefulWidget {
  const RootLogsScreen({super.key});

  @override
  State<RootLogsScreen> createState() => _RootLogsScreenState();
}

class _RootLogsScreenState extends State<RootLogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Simulated log audit list
    final List<Map<String, dynamic>> allLogs = [
      {'level': 'INFO', 'message': "usuario@test.com generó 'Realeza Imperial'", 'time': 'Hace 2 min'},
      {'level': 'INFO', 'message': 'Nueva cuenta registrada: María G.', 'time': 'Ayer 12:45'},
      {'level': 'ERROR', 'message': 'Fallo API Gemini en simulación #334', 'time': 'Ayer 10:15'},
      {'level': 'WARN', 'message': 'Reglas Firestore actualizadas', 'time': 'Hace 3 días'},
      {'level': 'INFO', 'message': 'carlos.p@gmail.com inició sesión', 'time': 'Hace 5 días'},
      {'level': 'ERROR', 'message': 'Storage upload failed - userid: abc123', 'time': 'Hace 8 días'},
      {'level': 'INFO', 'message': 'Seed ejecutado correctamente', 'time': 'Hace 10 días'},
    ];

    // Filter logs
    final filteredLogs = allLogs.where((log) {
      final tabIndex = _tabController.index;
      if (tabIndex == 0) return true; // Todos
      if (tabIndex == 1) return log['level'] == 'ERROR';
      if (tabIndex == 2) return log['level'] == 'INFO';
      if (tabIndex == 3) return log['level'] == 'WARN';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs & Métricas', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Chart Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'Simulaciones — últimos 7 días',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('L', 0.5, '12', isDark),
                  _buildBar('M', 0.7, '18', isDark),
                  _buildBar('M', 0.45, '11', isDark),
                  _buildBar('J', 0.65, '16', isDark),
                  _buildBar('V', 0.95, '24', isDark, isHighlight: true),
                  _buildBar('S', 0.8, '20', isDark),
                  _buildBar('D', 0.3, '8', isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Filters TabBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                Tab(text: 'Error'),
                Tab(text: 'Info'),
                Tab(text: 'Warn'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Logs audit feed list
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(child: Text('No hay logs para este nivel.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (context, idx) => Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 12,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final level = log['level'] as String;
                      final message = log['message'] as String;
                      final time = log['time'] as String;

                      Color badgeColor;
                      switch (level) {
                        case 'ERROR':
                          badgeColor = AppTheme.redAccent;
                          break;
                        case 'WARN':
                          badgeColor = AppTheme.goldAccent;
                          break;
                        case 'INFO':
                        default:
                          badgeColor = AppTheme.greenAccent;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Level Badge
                            Container(
                              width: 52,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                level,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    time,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightPct, String count, bool isDark, {bool isHighlight = false}) {
    final barColor = isHighlight ? AppTheme.redAccent : (isDark ? Colors.grey[700] : Colors.grey[300]);
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: 100 * heightPct,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
