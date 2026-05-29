import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/report.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter pending reports
    final pendingReports = state.reports.where((r) => !r.isResolved).toList();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE61D63), Color(0xFF7B2CBF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Moderación & Estadísticas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row of stats cards
            Row(
              children: [
                _buildStatCard(
                  title: '${state.reports.length}',
                  subtitle: 'Reportes',
                  color: AppTheme.redAccent,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  title: '${pendingReports.length}',
                  subtitle: 'Pendientes',
                  color: AppTheme.goldAccent,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  title: '98%',
                  subtitle: 'Aprobados',
                  color: AppTheme.greenAccent,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Bar Chart Section
            Text(
              'Uso por estilo (últimos 10 días)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(label: 'Real', heightPct: 0.9, uses: '234', color: const Color(0xFFE61D63)),
                      _buildBar(label: 'Cosm', heightPct: 0.7, uses: '159', color: const Color(0xFFE61D63).withValues(alpha: 0.65)),
                      _buildBar(label: 'Cybr', heightPct: 0.55, uses: '89', color: AppTheme.greenAccent),
                      _buildBar(label: 'Acua', heightPct: 0.25, uses: '12', color: AppTheme.goldAccent),
                      _buildBar(label: 'Stea', heightPct: 0.45, uses: '78', color: Colors.blueAccent),
                      _buildBar(label: 'Kawa', heightPct: 0.15, uses: '0', color: AppTheme.redAccent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estilos Populares', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text('Estadísticas en tiempo real', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Pending Reports Section
            Text(
              'Reportes Pendientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            pendingReports.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '¡No hay reportes pendientes de revisión!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingReports.length,
                      separatorBuilder: (context, idx) => Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final report = pendingReports[index];
                        return _buildReportItem(context, report, isDark);
                      },
                    ),
                  ),
            const SizedBox(height: 28),

            // Recent Activity Section
            Text(
              'Actividad Reciente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildLogItem(
                    text: "cliente_prueba generó 'Realeza Imperial'",
                    time: "hace 2 min",
                    dotColor: const Color(0xFFE61D63),
                  ),
                  _buildDivider(isDark),
                  _buildLogItem(
                    text: "Nuevo usuario registrado: laura.m@gmail.com",
                    time: "hace 6 min",
                    dotColor: AppTheme.greenAccent,
                  ),
                  _buildDivider(isDark),
                  _buildLogItem(
                    text: "Error en simulación de carlos.p",
                    time: "hace 10 min",
                    dotColor: AppTheme.redAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required double heightPct,
    required String uses,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          uses,
          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: 100 * heightPct,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildReportItem(BuildContext context, ModerationReport report, bool isDark) {
    final state = Provider.of<AppStateProvider>(context, listen: false);

    Color priorityColor;
    if (report.priority == 'Alta') {
      priorityColor = AppTheme.redAccent;
    } else if (report.priority == 'Media') {
      priorityColor = AppTheme.goldAccent;
    } else {
      priorityColor = Colors.grey;
    }

    final initial = report.userEmail.isNotEmpty ? report.userEmail[0].toUpperCase() : 'M';
    final userPrefix = report.userEmail.split('@').first;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // User Avatar bubble
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: priorityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Report Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userPrefix,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  report.reason,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Resolve Button (Green checkmark icon)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.greenAccent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.check, color: AppTheme.greenAccent, size: 16),
              onPressed: () async {
                await state.resolveReport(report.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reporte marcado como resuelto.')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem({
    required String text,
    required String time,
    required Color dotColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 36,
      endIndent: 12,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }
}
