import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/priority_chip.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final greeting = auth.userName != null && auth.userName!.isNotEmpty
        ? 'Bonjour, ${auth.userName} 👋'
        : 'Bonjour 👋';

    // Get 3 most recent pending tasks
    final recentTasks = taskProvider.pendingTasks.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prêt pour une session productive ?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 32),
            
            // Résumé du jour
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [AppTheme.surfaceDark, AppTheme.surface2Dark]
                      : [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppTheme.primaryColor).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Résumé du jour',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryMetric(context, 'Tâches', taskProvider.completedTasks.length.toString(), isDark),
                      _buildSummaryMetric(context, 'En cours', taskProvider.pendingTasks.length.toString(), isDark),
                      _buildSummaryMetric(context, 'Focus', timerProvider.isRunning ? '1' : '0', isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // En cours
            Text(
              'En cours',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: timerProvider.isRunning 
                          ? AppTheme.primaryColor.withOpacity(0.15)
                          : AppTheme.textSecondaryLight.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      timerProvider.isRunning ? Icons.timer : Icons.timer_off,
                      color: timerProvider.isRunning ? AppTheme.primaryColor : AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timerProvider.currentTask?.title ?? (timerProvider.isRunning ? 'Session Libre' : 'Aucune session active'),
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timerProvider.isRunning 
                              ? 'Temps restant : ${timerProvider.timeFormatted}' 
                              : 'Prêt à démarrer un Pomodoro',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tâches récentes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tâches récentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Aucune tâche en cours.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
            else
              ...recentTasks.map((task) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle_outlined, color: AppTheme.primaryColor, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    PriorityChip(priority: task.priority),
                  ],
                ),
              )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TasksScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryMetric(BuildContext context, String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                color: isDark ? AppTheme.secondaryColor : Colors.white,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : Colors.white70,
              ),
        ),
      ],
    );
  }
}
