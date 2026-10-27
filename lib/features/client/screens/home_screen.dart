import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import 'history_screen.dart';
import 'tutorials_screen.dart';
import 'coat_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = state.language;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header purple container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Greeting & Avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'English'
                                ? 'Good morning ☀️'
                                : lang == 'Português'
                                    ? 'Bom dia ☀️'
                                    : 'Buenos días ☀️',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Avatar "VL" or Photo
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.goldAccent.withValues(alpha: 0.2),
                          border: Border.all(color: AppTheme.goldAccent, width: 2),
                        ),
                        child: ClipOval(
                          child: state.userPhoto.isNotEmpty
                              ? (state.userPhoto.startsWith('assets/')
                                  ? Image.asset(
                                      state.userPhoto,
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(state.userPhoto),
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildInitials(state.userName),
                                    ))
                              : _buildInitials(state.userName),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Statistic badges
                  Row(
                    children: [
                      _buildHeaderBadge(
                        context,
                        Icons.palette_outlined,
                        lang == 'English'
                            ? '${state.styles.length} styles'
                            : '${state.styles.length} estilos',
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderBadge(
                        context,
                        Icons.pets_outlined,
                        lang == 'English'
                            ? '${state.pets.length} pets'
                            : lang == 'Português'
                                ? '${state.pets.length} animais'
                                : '${state.pets.length} mascotas',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Acceso Rápido
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                lang == 'English' ? 'Quick Access' : 'Acceso Rápido',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(
                    context,
                    label: lang == 'English'
                        ? 'New Simulation'
                        : lang == 'Português'
                            ? 'Nova Simulação'
                            : 'Nueva Simulación',
                    icon: Icons.auto_awesome,
                    iconColor: Colors.pinkAccent,
                    onTap: () => state.setNavIndex(2), // Simular
                  ),
                  _buildQuickAction(
                    context,
                    label: lang == 'English'
                        ? 'Styles Catalog'
                        : 'Catálogo de Estilos',
                    icon: Icons.book,
                    iconColor: Colors.orangeAccent,
                    onTap: () => state.setNavIndex(1), // Estilos
                  ),
                  _buildQuickAction(
                    context,
                    label: lang == 'English'
                        ? 'My History'
                        : lang == 'Português'
                            ? 'Meu Histórico'
                            : 'Mi Historial',
                    icon: Icons.folder,
                    iconColor: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                  _buildQuickAction(
                    context,
                    label: lang == 'English'
                        ? 'Tutorials'
                        : lang == 'Português'
                            ? 'Tutoriais'
                            : 'Tutoriales',
                    icon: Icons.play_circle_fill,
                    iconColor: Colors.greenAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TutorialsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Banner Destacado: Escáner Facial y Manto con IA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2575FC).withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CoatScannerScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'NUEVA IA GEMINI VISION',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Escáner Facial & Manto',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Diagnostica lagrimales, área ocular y descubre el corte ideal para tu Shih Tzu.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Escanear Ahora',
                                        style: TextStyle(
                                          color: Color(0xFF6A11CB),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward, size: 14, color: Color(0xFF6A11CB)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.document_scanner_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tendencia esta semana
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      final hotStyle = state.styles.isNotEmpty
                          ? state.styles.firstWhere((s) => s.isHot, orElse: () => state.styles.first)
                          : null;
                      if (hotStyle != null) {
                        final petToUse = state.pets.isNotEmpty ? state.pets.first : null;
                        state.selectStyleForSimulation(hotStyle, pet: petToUse);
                      } else {
                        state.setNavIndex(2);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                lang == 'English'
                                    ? 'Trending this week'
                                    : lang == 'Português'
                                        ? 'Tendência esta semana'
                                        : 'Tendencia esta semana',
                                style: TextStyle(
                                  color: Colors.orange[300],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.styles.isNotEmpty
                                ? state.styles.firstWhere((s) => s.isHot, orElse: () => state.styles.first).name
                                : 'Corte Oso de Peluche',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang == 'English'
                                    ? 'More than 200 users used it'
                                    : lang == 'Português'
                                        ? 'Mais de 200 usuários usaram'
                                        : 'Más de 200 usuarios lo usaron',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mis Creaciones Recientes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang == 'English'
                        ? 'My Recent Creations'
                        : lang == 'Português'
                            ? 'Minhas Criações Recentes'
                            : 'Mis Creaciones Recientes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          lang == 'English'
                              ? 'See all'
                              : lang == 'Português'
                                  ? 'Ver tudo'
                                  : 'Ver todo',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: state.creations.isEmpty
                  ? Center(
                      child: Text(
                        lang == 'English'
                            ? 'You have no creations yet.'
                            : lang == 'Português'
                                ? 'Você ainda não tem criações.'
                                : 'Aún no tienes creaciones.',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: state.creations.take(3).length,
                      itemBuilder: (context, index) {
                        final creation = state.creations[index];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Thumbnail
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Image.asset(
                                  creation.imagePath,
                                  height: 100,
                                  width: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      creation.styleName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTimeAgo(creation.date, lang),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                      ),
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
            const SizedBox(height: 24),

            // Tutoriales
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                lang == 'English'
                    ? 'Tutorials'
                    : lang == 'Português'
                        ? 'Tutoriais'
                        : 'Tutoriales',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 0,
                color: isDark ? AppTheme.cardDark : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Play Circle Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang == 'English' ? 'Basic Puppy Cut' : 'Corte Puppy Cut básico',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lang == 'English'
                                  ? '12:45 mins • Beginner'
                                  : lang == 'Português'
                                      ? '12:45 mins • Iniciante'
                                      : '12:45 mins • Principiante',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date, String lang) {
    final diff = DateTime.now().difference(date);
    if (lang == 'English') {
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } else if (lang == 'Português') {
      if (diff.inMinutes < 60) {
        return 'há ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        return 'há ${diff.inHours}h';
      } else {
        return 'há ${diff.inDays}d';
      }
    } else {
      if (diff.inMinutes < 60) {
        return 'hace ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        return 'hace ${diff.inHours}h';
      } else {
        return 'hace ${diff.inDays}d';
      }
    }
  }

  Widget _buildInitials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty
            ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
            : 'VL',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
