import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/tutorial.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();

  static void openTutorialGuide(BuildContext context, Tutorial tutorial) =>
      _TutorialsScreenState.openTutorialGuide(context, tutorial);
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todos'; // 'Todos', 'Favoritos', 'Cortes', 'Cepillado', 'Higiene', 'Baño'
  String _selectedDifficulty = 'Todos'; // 'Todos', 'Fácil', 'Medio', 'Difícil'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final publishedTutorials = state.tutorials.where((t) => t.status == 'publicado').toList();
    final completedCount = publishedTutorials.where((t) => state.isTutorialCompleted(t.id)).length;
    final progress = publishedTutorials.isEmpty ? 0.0 : (completedCount / publishedTutorials.length).clamp(0.0, 1.0);

    // Filter tutorials
    final filteredTutorials = publishedTutorials.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.steps.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesDifficulty = _selectedDifficulty == 'Todos' || t.difficulty == _selectedDifficulty;

      bool matchesCategory = true;
      if (_selectedCategory == 'Favoritos') {
        matchesCategory = state.isTutorialFavorite(t.id);
      } else if (_selectedCategory != 'Todos') {
        matchesCategory = t.category.toLowerCase() == _selectedCategory.toLowerCase();
      }

      return matchesSearch && matchesDifficulty && matchesCategory;
    }).toList();

    final categories = [
      {'key': 'Todos', 'label': state.translate('tutorials_tab_all'), 'icon': null},
      {'key': 'Favoritos', 'label': state.translate('tutorials_tab_favs'), 'icon': Icons.favorite_rounded},
      {'key': 'Cortes', 'label': state.translate('tutorials_tab_cuts'), 'icon': Icons.content_cut_rounded},
      {'key': 'Cepillado', 'label': state.translate('tutorials_tab_brushing'), 'icon': Icons.brush_rounded},
      {'key': 'Higiene', 'label': state.translate('tutorials_tab_hygiene'), 'icon': Icons.clean_hands_rounded},
      {'key': 'Baño', 'label': state.translate('tutorials_tab_bath'), 'icon': Icons.shower_rounded},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(state.translate('tutorials_title')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Header Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF9333EA), Color(0xFFE61D63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppTheme.goldAccent, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            state.translate('tutorials_progress_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.translate(
                      'tutorials_progress_sub',
                      params: {
                        'completed': completedCount.toString(),
                        'total': publishedTutorials.length.toString(),
                      },
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: state.translate('tutorials_search_hint'),
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppTheme.cardDark : const Color(0xFFF4F0FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category Chips Row
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final key = cat['key'] as String;
                final label = cat['label'] as String;
                final icon = cat['icon'] as IconData?;
                final isSelected = _selectedCategory == key;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    showCheckmark: false,
                    avatar: icon != null
                        ? Icon(
                            icon,
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : (key == 'Favoritos' ? AppTheme.redAccent : AppTheme.primaryColor),
                          )
                        : null,
                    label: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: key == 'Favoritos' ? AppTheme.redAccent : AppTheme.primaryColor,
                    backgroundColor: isDark ? AppTheme.cardDark : const Color(0xFFF0EBF8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = key;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Difficulty Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['Todos', 'Fácil', 'Medio', 'Difícil'].map((diff) {
                final isSelected = _selectedDifficulty == diff;
                Color chipColor;
                switch (diff) {
                  case 'Fácil':
                    chipColor = AppTheme.greenAccent;
                    break;
                  case 'Medio':
                    chipColor = AppTheme.goldAccent;
                    break;
                  case 'Difícil':
                    chipColor = AppTheme.redAccent;
                    break;
                  default:
                    chipColor = AppTheme.primaryColor;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDifficulty = diff),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? chipColor.withValues(alpha: 0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? chipColor : Colors.grey.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        diff,
                        style: TextStyle(
                          color: isSelected ? chipColor : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Tutorials List
          Expanded(
            child: filteredTutorials.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedCategory == 'Favoritos'
                              ? Icons.favorite_border_rounded
                              : Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedCategory == 'Favoritos'
                              ? state.translate('tutorials_no_favs')
                              : state.translate('tutorials_no_results'),
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    itemCount: filteredTutorials.length,
                    itemBuilder: (context, index) {
                      final tutorial = filteredTutorials[index];
                      return _buildTutorialCard(context, tutorial);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(BuildContext context, Tutorial tutorial) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = state.isTutorialFavorite(tutorial.id);
    final isCompleted = state.isTutorialCompleted(tutorial.id);

    Color diffColor;
    switch (tutorial.difficulty) {
      case 'Fácil':
        diffColor = AppTheme.greenAccent;
        break;
      case 'Medio':
        diffColor = AppTheme.goldAccent;
        break;
      case 'Difícil':
      default:
        diffColor = AppTheme.redAccent;
        break;
    }

    // Category icon
    IconData catIcon;
    switch (tutorial.category) {
      case 'Cortes':
        catIcon = Icons.content_cut_rounded;
        break;
      case 'Cepillado':
        catIcon = Icons.brush_rounded;
        break;
      case 'Higiene':
        catIcon = Icons.clean_hands_rounded;
        break;
      case 'Baño':
        catIcon = Icons.shower_rounded;
        break;
      default:
        catIcon = Icons.pets;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCompleted
            ? Border.all(color: AppTheme.greenAccent.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openTutorialGuide(context, tutorial),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with Play button & Category icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCompleted
                              ? [const Color(0xFF059669), const Color(0xFF10B981)]
                              : [const Color(0xFF7B2CBF), const Color(0xFFE61D63)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(catIcon, color: Colors.white.withValues(alpha: 0.25), size: 40),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                        color: isCompleted ? AppTheme.greenAccent : AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              tutorial.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                height: 1.25,
                              ),
                            ),
                          ),
                          // Heart favorite button
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => state.toggleFavoriteTutorial(tutorial.id),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? AppTheme.redAccent : Colors.grey[400],
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Time & Views
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            tutorial.duration,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.visibility_outlined, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            state.translate('tutorials_views', params: {'count': tutorial.views.toString()}),
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Badges Row (Difficulty, Category, Completed)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Difficulty
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tutorial.difficulty,
                              style: TextStyle(
                                color: diffColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          // Category
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tutorial.category,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          // YouTube Video badge
                          if (tutorial.videoUrl.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0000).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF0000), size: 10),
                                  SizedBox(width: 3),
                                  Text(
                                    'YouTube',
                                    style: TextStyle(
                                      color: Color(0xFFFF0000),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Completed badge
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.greenAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, size: 10, color: AppTheme.greenAccent),
                                  const SizedBox(width: 2),
                                  Text(
                                    state.translate('tutorials_completed_badge'),
                                    style: const TextStyle(
                                      color: AppTheme.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void openTutorialGuide(BuildContext context, Tutorial tutorial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => TutorialDetailSheet(tutorial: tutorial),
    );
  }
}

class TutorialDetailSheet extends StatefulWidget {
  final Tutorial tutorial;

  const TutorialDetailSheet({super.key, required this.tutorial});

  @override
  State<TutorialDetailSheet> createState() => _TutorialDetailSheetState();
}

class _TutorialDetailSheetState extends State<TutorialDetailSheet> {
  YoutubePlayerController? _youtubeController;
  final Set<int> _checkedSteps = {};
  bool _isPlayingMock = true;
  double _playProgressMock = 0.42;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    if (widget.tutorial.videoUrl.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(widget.tutorial.videoUrl.trim());
      if (videoId != null && videoId.isNotEmpty) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            isLive: false,
            forceHD: false,
            loop: false,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = state.isTutorialFavorite(widget.tutorial.id);
    final isCompleted = state.isTutorialCompleted(widget.tutorial.id);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Pull handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // In-App Video Player or Simulated fallback
          _buildPlayerWidget(context),

          // Scrollable content (Title, Actions, Tools, Steps)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Title
                Text(
                  widget.tutorial.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Player mode indicator & duration
                Row(
                  children: [
                    if (_youtubeController != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill, color: Color(0xFFFF0000), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Reproduciendo en la app',
                              style: TextStyle(
                                color: Color(0xFFFF0000),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.tutorial.duration,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Optional external open button if desired
                if (widget.tutorial.videoUrl.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(widget.tutorial.videoUrl.trim());
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFFFF0000)),
                      label: const Text(
                        'Abrir en la aplicación de YouTube',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFFFF0000),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF0000), width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Actions Row: Favorite & Completed
                Row(
                  children: [
                    // Favorite Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          state.toggleFavoriteTutorial(widget.tutorial.id);
                        },
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppTheme.redAccent : Colors.grey,
                          size: 18,
                        ),
                        label: Text(
                          isFav ? 'Favorito' : 'Guardar',
                          style: TextStyle(
                            color: isFav ? AppTheme.redAccent : (isDark ? Colors.white : Colors.black87),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isFav ? AppTheme.redAccent : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Mark Completed Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          state.toggleCompletedTutorial(widget.tutorial.id);
                        },
                        icon: Icon(
                          isCompleted ? Icons.check_circle_rounded : Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          isCompleted
                              ? state.translate('tutorials_completed_badge')
                              : state.translate('tutorials_mark_completed'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted ? AppTheme.greenAccent : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tools Needed Section
                if (widget.tutorial.tools.isNotEmpty) ...[
                  Text(
                    state.translate('tutorials_tools_needed'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.tutorial.tools.map((tool) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : const Color(0xFFF4F0FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.construction_rounded,
                              size: 13,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tool,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Step by step technique Section
                if (widget.tutorial.steps.isNotEmpty) ...[
                  Text(
                    state.translate('tutorials_steps_title'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.tutorial.steps.asMap().entries.map((entry) {
                    final stepIdx = entry.key;
                    final stepText = entry.value;
                    final isStepDone = _checkedSteps.contains(stepIdx);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isStepDone) {
                            _checkedSteps.remove(stepIdx);
                          } else {
                            _checkedSteps.add(stepIdx);
                            if (_checkedSteps.length == widget.tutorial.steps.length && !isCompleted) {
                              state.toggleCompletedTutorial(widget.tutorial.id);
                            }
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isStepDone
                              ? AppTheme.greenAccent.withValues(alpha: 0.1)
                              : (isDark ? AppTheme.cardDark : Colors.grey[50]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isStepDone
                                ? AppTheme.greenAccent.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isStepDone
                                    ? AppTheme.greenAccent
                                    : AppTheme.primaryColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isStepDone
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : Text(
                                        '${stepIdx + 1}',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                stepText,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: isStepDone
                                      ? (isDark ? Colors.grey[400] : Colors.grey[600])
                                      : (isDark ? Colors.white : Colors.black87),
                                  decoration: isStepDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      state.translate('tutorials_btn_close'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerWidget(BuildContext context) {
    if (_youtubeController != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFFFF0000),
              progressColors: const ProgressBarColors(
                playedColor: Color(0xFFFF0000),
                handleColor: Color(0xFFFF0000),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
              bottomActions: [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
                const PlaybackSpeedButton(),
              ],
            ),
          ),
        ),
      );
    }

    // Fallback simulation player
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 190,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF311042)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.movie_creation_outlined,
              color: Colors.white.withValues(alpha: 0.15),
              size: 64,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isPlayingMock = !_isPlayingMock;
            });
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              _isPlayingMock ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 32,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.hd_outlined, color: AppTheme.goldAccent, size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.tutorial.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 32,
          right: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isPlayingMock = !_isPlayingMock),
                    child: Icon(
                      _isPlayingMock ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: AppTheme.goldAccent,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppTheme.goldAccent,
                      ),
                      child: Slider(
                        value: _playProgressMock,
                        onChanged: (val) {
                          setState(() => _playProgressMock = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.tutorial.duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
