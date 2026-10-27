import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final state = Provider.of<AppStateProvider>(dialogContext);
        return SimpleDialog(
          title: Text(state.translate('settings_language')),
          children: ['Español', 'English', 'Português'].map((lang) {
            return SimpleDialogOption(
              onPressed: () {
                state.setLanguage(lang);
                Navigator.pop(dialogContext);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lang),
                  if (state.language == lang)
                    const Icon(Icons.check, color: AppTheme.primaryColor),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final controller = TextEditingController(text: state.geminiApiKey);
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final hasKey = state.geminiApiKey.isNotEmpty;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.translate('settings_gemini_dialog_title'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.translate('settings_gemini_dialog_desc'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    obscureText: obscureText,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: state.translate('settings_gemini_input_label'),
                      hintText: state.translate('settings_gemini_input_hint'),
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDark : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.key, color: AppTheme.primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                if (hasKey)
                  TextButton.icon(
                    onPressed: () async {
                      await state.setGeminiApiKey('');
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            content: Text(state.translate('settings_gemini_cleared_snack')),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.redAccent),
                    label: Text(
                      state.translate('settings_gemini_btn_clear'),
                      style: const TextStyle(color: AppTheme.redAccent, fontSize: 13),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    state.translate('profile_btn_cancel'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: () async {
                    final newKey = controller.text.trim();
                    await state.setGeminiApiKey(newKey);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.greenAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.translate('settings_gemini_saved_snack'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    state.translate('settings_gemini_btn_save'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.translate('settings_title')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          // APARIENCIA
          _buildSectionHeader(state.translate('settings_header_appearance')),
          _buildSettingCard([
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: state.translate('settings_dark_mode'),
              subtitle: state.translate('settings_dark_mode_sub'),
              value: state.isDarkMode,
              onChanged: (val) => state.toggleDarkMode(val),
            ),
            _buildDivider(isDark),
            _buildNavigationTile(
              icon: Icons.language_outlined,
              title: state.translate('settings_language'),
              trailingText: state.language,
              onTap: _showLanguageDialog,
            ),
          ]),
          const SizedBox(height: 24),

          // INTELIGENCIA ARTIFICIAL (IA)
          _buildSectionHeader(state.translate('settings_header_ai')),
          _buildSettingCard([
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 18),
              ),
              title: Text(
                state.translate('settings_gemini_api'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                state.geminiApiKey.isNotEmpty
                    ? state.translate('settings_gemini_api_sub_active')
                    : state.translate('settings_gemini_api_sub_inactive'),
                style: TextStyle(
                  color: state.geminiApiKey.isNotEmpty ? AppTheme.greenAccent : Colors.grey,
                  fontSize: 11,
                  fontWeight: state.geminiApiKey.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: state.geminiApiKey.isNotEmpty
                          ? AppTheme.greenAccent.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.geminiApiKey.isNotEmpty
                          ? state.translate('settings_gemini_badge_active')
                          : state.translate('settings_gemini_badge_sim'),
                      style: TextStyle(
                        color: state.geminiApiKey.isNotEmpty ? AppTheme.greenAccent : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                ],
              ),
              onTap: () => _showApiKeyDialog(context),
            ),
          ]),
          const SizedBox(height: 24),

          // NOTIFICACIONES
          _buildSectionHeader(state.translate('settings_header_notif')),
          _buildSettingCard([
            _buildSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: state.translate('settings_notif_push'),
              subtitle: state.translate('settings_notif_push_sub'),
              value: state.pushNotifications,
              onChanged: (val) => state.setPushNotifications(val),
            ),
            _buildDivider(isDark),
            _buildSwitchTile(
              icon: Icons.mail_outline_outlined,
              title: state.translate('settings_notif_email'),
              subtitle: state.translate('settings_notif_email_sub'),
              value: state.emailNotifications,
              onChanged: (val) => state.setEmailNotifications(val),
            ),
          ]),

          const SizedBox(height: 24),

          // CUENTA
          _buildSectionHeader(state.translate('settings_header_account')),
          _buildSettingCard([
            _buildNavigationTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: AppTheme.redAccent,
              title: state.translate('settings_clear_history'),
              subtitle: state.translate('settings_clear_history_sub'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(state.translate('settings_clear_confirm')),
                    content: Text(state.translate('settings_clear_desc')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(state.translate('profile_btn_cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          state.clearHistory();
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.translate('settings_clear_success'),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          state.translate('settings_btn_delete_all'),
                          style: const TextStyle(color: AppTheme.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? AppTheme.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 48,
      endIndent: 12,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    Color iconColor = AppTheme.primaryColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          if (trailingText != null) const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }
}
