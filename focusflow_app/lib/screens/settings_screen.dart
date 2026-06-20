import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle(context, 'Apparence'),
          _buildCard(
            context,
            isDark,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.dark_mode, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Mode Sombre'),
                  trailing: Switch(
                    value: settings.isDarkMode,
                    activeTrackColor: AppTheme.primaryColor.withOpacity(0.5),
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) {
                      context.read<SettingsProvider>().toggleTheme();
                    },
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined, color: AppTheme.secondaryColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'De nouveaux thèmes colorés seront bientôt disponibles !',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle(context, 'Minuteur Pomodoro'),
          _buildCard(
            context,
            isDark,
            child: Column(
              children: [
                _buildDurationSetting(
                  context,
                  title: 'Focus',
                  value: settings.pomodoroDuration,
                  onDecrease: settings.pomodoroDuration > 5
                      ? () => context.read<SettingsProvider>().setPomodoroDuration(settings.pomodoroDuration - 5)
                      : null,
                  onIncrease: settings.pomodoroDuration < 120
                      ? () => context.read<SettingsProvider>().setPomodoroDuration(settings.pomodoroDuration + 5)
                      : null,
                ),
                const Divider(),
                _buildDurationSetting(
                  context,
                  title: 'Pause Courte',
                  value: settings.shortBreakDuration,
                  onDecrease: settings.shortBreakDuration > 1
                      ? () => context.read<SettingsProvider>().setShortBreakDuration(settings.shortBreakDuration - 1)
                      : null,
                  onIncrease: settings.shortBreakDuration < 30
                      ? () => context.read<SettingsProvider>().setShortBreakDuration(settings.shortBreakDuration + 1)
                      : null,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          _buildSectionTitle(context, 'Compte'),
          _buildCard(
            context,
            isDark,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline, color: AppTheme.textSecondaryLight),
              ),
              title: Text(auth.userName ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('FocusFlow Membre'),
            ),
          ),

          const SizedBox(height: 48),

          GradientButton(
            text: 'Se déconnecter',
            gradient: const LinearGradient(
              colors: [AppTheme.error, Color(0xFFEF4444)], // Red gradient
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondaryLight)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                auth.logout();
                if (context.mounted) {
                  Navigator.pop(context); // Close settings screen
                }
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
        ),
      ),
      child: child,
    );
  }

  Widget _buildDurationSetting(
    BuildContext context, {
    required String title,
    required int value,
    required VoidCallback? onDecrease,
    required VoidCallback? onIncrease,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.surfaceDark 
                  : AppTheme.surface2Light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: onDecrease,
                  color: onDecrease == null ? Theme.of(context).disabledColor : AppTheme.primaryColor,
                  splashRadius: 20,
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    value.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onIncrease,
                  color: onIncrease == null ? Theme.of(context).disabledColor : AppTheme.primaryColor,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
