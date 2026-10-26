import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ComparatorDisplayMode {
  slider,
  toggle,
  sideBySide,
}

class BeforeAfterComparator extends StatefulWidget {
  final String beforeImagePath;
  final String afterImagePath;
  final String beforeLabel;
  final String afterLabel;
  final double height;
  final bool showControls;
  final VoidCallback? onFullScreenTap;

  const BeforeAfterComparator({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    this.beforeLabel = 'Antes',
    this.afterLabel = 'Después',
    this.height = 290,
    this.showControls = true,
    this.onFullScreenTap,
  });

  @override
  State<BeforeAfterComparator> createState() => _BeforeAfterComparatorState();
}

class _BeforeAfterComparatorState extends State<BeforeAfterComparator>
    with SingleTickerProviderStateMixin {
  ComparatorDisplayMode _mode = ComparatorDisplayMode.slider;
  double _sliderValue = 0.5; // 0.0 (all after) to 1.0 (all before)
  bool _showingBeforeInToggle = false;
  bool _userHasInteracted = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.pets, color: Colors.grey, size: 40),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showControls) ...[
          // Toolbar with mode selectors + fullscreen button
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mode selector pills
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF221738) : const Color(0xFFF0ECF8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeButton(
                        mode: ComparatorDisplayMode.slider,
                        icon: Icons.splitscreen,
                        tooltip: 'Deslizador',
                      ),
                      _buildModeButton(
                        mode: ComparatorDisplayMode.toggle,
                        icon: Icons.touch_app_outlined,
                        tooltip: 'Alternar',
                      ),
                      _buildModeButton(
                        mode: ComparatorDisplayMode.sideBySide,
                        icon: Icons.view_column_outlined,
                        tooltip: 'Lado a lado',
                      ),
                    ],
                  ),
                ),

                // Fullscreen button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.onFullScreenTap ?? () => _openFullscreenModal(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF221738) : const Color(0xFFF0ECF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fullscreen,
                            size: 18,
                            color: isDark ? Colors.white70 : AppTheme.primaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Zoom',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Visual Display Area
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: widget.height,
            width: double.infinity,
            color: isDark ? AppTheme.cardDark : Colors.grey[200],
            child: _buildCurrentModeContent(),
          ),
        ),

        // Bottom instruction tip
        const SizedBox(height: 8),
        Center(
          child: Text(
            _getModeHelperText(),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  String _getModeHelperText() {
    switch (_mode) {
      case ComparatorDisplayMode.slider:
        return '↔️ Desliza la barra central para comparar el antes y después';
      case ComparatorDisplayMode.toggle:
        return '👆 Toca o mantén presionado para alternar entre el original y el corte';
      case ComparatorDisplayMode.sideBySide:
        return '🔍 Vista comparativa directa del original y el nuevo estilo';
    }
  }

  Widget _buildModeButton({
    required ComparatorDisplayMode mode,
    required IconData icon,
    required String tooltip,
  }) {
    final isSelected = _mode == mode;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mode = mode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              if (isSelected) ...[
                const SizedBox(width: 5),
                Text(
                  tooltip,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentModeContent() {
    switch (_mode) {
      case ComparatorDisplayMode.slider:
        return _buildSliderComparator();
      case ComparatorDisplayMode.toggle:
        return _buildToggleComparator();
      case ComparatorDisplayMode.sideBySide:
        return _buildSideBySideComparator();
    }
  }

  // --- SLIDER COMPARATOR ---
  Widget _buildSliderComparator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _userHasInteracted = true;
              _sliderValue = (_sliderValue + (details.delta.dx / totalWidth)).clamp(0.02, 0.98);
            });
          },
          onTapDown: (details) {
            setState(() {
              _userHasInteracted = true;
              _sliderValue = (details.localPosition.dx / totalWidth).clamp(0.02, 0.98);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: AFTER image (Corte Estilizado)
              _buildImage(
                widget.afterImagePath,
                width: totalWidth,
                height: totalHeight,
                fit: BoxFit.cover,
              ),

              // Foreground: BEFORE image (Foto Original) clipped to slider value
              ClipRect(
                clipper: _RectClipper(fraction: _sliderValue),
                child: _buildImage(
                  widget.beforeImagePath,
                  width: totalWidth,
                  height: totalHeight,
                  fit: BoxFit.cover,
                ),
              ),

              // Floating Badge "ANTES" (Top-Left)
              Positioned(
                top: 12,
                left: 12,
                child: _buildBadge(
                  label: widget.beforeLabel,
                  icon: Icons.history,
                  backgroundColor: Colors.black.withValues(alpha: 0.65),
                  textColor: Colors.white,
                ),
              ),

              // Floating Badge "DESPUÉS" (Top-Right)
              Positioned(
                top: 12,
                right: 12,
                child: _buildBadge(
                  label: widget.afterLabel,
                  icon: Icons.auto_awesome,
                  backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.85),
                  textColor: AppTheme.goldAccent,
                ),
              ),

              // Center vertical divider bar
              Positioned(
                left: (totalWidth * _sliderValue) - 1.5,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Central draggable grab handle
              Positioned(
                left: (totalWidth * _sliderValue) - 20,
                top: (totalHeight / 2) - 20,
                child: ScaleTransition(
                  scale: _userHasInteracted ? const AlwaysStoppedAnimation(1.0) : _pulseAnimation,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppTheme.primaryColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_left, size: 14, color: AppTheme.primaryColor),
                        Icon(Icons.arrow_right, size: 14, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TOGGLE COMPARATOR ---
  Widget _buildToggleComparator() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _showingBeforeInToggle = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _showingBeforeInToggle = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _showingBeforeInToggle = false;
        });
      },
      onTap: () {
        setState(() {
          _showingBeforeInToggle = !_showingBeforeInToggle;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _showingBeforeInToggle
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildImage(
              widget.beforeImagePath,
              width: double.infinity,
              height: widget.height,
              fit: BoxFit.cover,
            ),
            secondChild: _buildImage(
              widget.afterImagePath,
              width: double.infinity,
              height: widget.height,
              fit: BoxFit.cover,
            ),
          ),

          // Active indicator pill
          Positioned(
            top: 14,
            left: 14,
            child: _buildBadge(
              label: _showingBeforeInToggle ? widget.beforeLabel : widget.afterLabel,
              icon: _showingBeforeInToggle ? Icons.history : Icons.auto_awesome,
              backgroundColor: _showingBeforeInToggle
                  ? Colors.black.withValues(alpha: 0.75)
                  : AppTheme.primaryDark.withValues(alpha: 0.85),
              textColor: _showingBeforeInToggle ? Colors.white : AppTheme.goldAccent,
            ),
          ),

          // Tap hint pill
          Positioned(
            bottom: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Mantén presionado',
                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SIDE BY SIDE COMPARATOR ---
  Widget _buildSideBySideComparator() {
    return Row(
      children: [
        // Left: BEFORE
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(
                widget.beforeImagePath,
                height: widget.height,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 10,
                left: 10,
                child: _buildBadge(
                  label: widget.beforeLabel,
                  icon: Icons.history,
                  backgroundColor: Colors.black.withValues(alpha: 0.65),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(width: 2, color: Colors.white),
        // Right: AFTER
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(
                widget.afterImagePath,
                height: widget.height,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _buildBadge(
                  label: widget.afterLabel,
                  icon: Icons.auto_awesome,
                  backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.85),
                  textColor: AppTheme.goldAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- FULLSCREEN ZOOM DIALOG ---
  void _openFullscreenModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: BeforeAfterComparator(
                        beforeImagePath: widget.beforeImagePath,
                        afterImagePath: widget.afterImagePath,
                        beforeLabel: widget.beforeLabel,
                        afterLabel: widget.afterLabel,
                        height: 480,
                        showControls: true,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  final double fraction;
  _RectClipper({required this.fraction});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(covariant _RectClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}
