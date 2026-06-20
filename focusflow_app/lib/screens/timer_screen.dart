import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_timer.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pDuration = settings.pomodoroDuration;
    final bDuration = settings.shortBreakDuration;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusFlow'),
      ),
      body: Consumer<TimerProvider>(
        builder: (context, timer, child) {
          // Sync timer with settings when not running
          if (!timer.isRunning) {
            Future.microtask(() => timer.syncWithSettings(pDuration, bDuration));
          }

          final maxDuration = timer.isBreak ? bDuration * 60 : pDuration * 60;
          final progress = timer.remainingSeconds / (maxDuration == 0 ? 1 : maxDuration);
          
          final phase = timer.isBreak 
              ? TimerPhase.shortBreak 
              : TimerPhase.focus;

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Session Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        timer.needsFeedback ? 'Feedback Requis' : (timer.isBreak ? 'Pause' : 'Session Focus'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    if (timer.needsFeedback)
                      _buildFeedbackCard(context, timer, taskProvider)
                    else ...[
                      // Circular Timer
                      CircularTimer(
                        progress: 1.0 - progress, // Arc grows as time passes
                        timeFormatted: timer.timeFormatted,
                        phase: phase,
                        size: 300,
                      ),
                      
                      if (!timer.isRunning && !timer.isBreak) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              onPressed: () {
                                final newDur = settings.pomodoroDuration > 5 ? settings.pomodoroDuration - 5 : 5;
                                settings.setPomodoroDuration(newDur);
                                timer.syncWithSettings(newDur, settings.shortBreakDuration);
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light),
                              ),
                              child: Text(
                                '${settings.pomodoroDuration} min',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              onPressed: () {
                                final newDur = settings.pomodoroDuration < 120 ? settings.pomodoroDuration + 5 : 120;
                                settings.setPomodoroDuration(newDur);
                                timer.syncWithSettings(newDur, settings.shortBreakDuration);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        const SizedBox(height: 32),
                      ],
                      
                      
                      // Task Link
                      _buildTaskLink(context, timer, taskProvider, isDark),
                      
                      const SizedBox(height: 40),

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Skip back (Reset)
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              timer.stopTimer(pDuration, bDuration);
                            },
                            icon: const Icon(Icons.replay),
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                            iconSize: 32,
                          ),
                          const SizedBox(width: 24),
                          
                          // Play / Pause
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              if (timer.isRunning) {
                                timer.pauseTimer();
                              } else {
                                timer.startTimer(pDuration, bDuration);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: timer.isRunning 
                                    ? null 
                                    : AppTheme.primaryGradient,
                                color: timer.isRunning 
                                    ? AppTheme.surface2Light 
                                    : null,
                                boxShadow: timer.isRunning ? [] : [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Icon(
                                timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: timer.isRunning ? (isDark ? Colors.white : AppTheme.textPrimaryLight) : Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 24),
                          
                          // Finish early
                          if (timer.isRunning)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    timer.finishEarly(pDuration, bDuration);
                                  },
                                  icon: const Icon(Icons.task_alt_rounded),
                                  color: Colors.green.withOpacity(0.8),
                                  iconSize: 32,
                                ),
                                Text(
                                  'Terminer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox(width: 32), // Placeholder to keep center alignment
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 48),

                    // Ambient Sounds
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSoundChip(context, settings, 'none', Icons.volume_off, 'Silence'),
                          const SizedBox(width: 12),
                          _buildSoundChip(context, settings, 'rain', Icons.water_drop, 'Pluie'),
                          const SizedBox(width: 12),
                          _buildSoundChip(context, settings, 'nature', Icons.park, 'Nature'),
                          const SizedBox(width: 12),
                          _buildSoundChip(context, settings, 'ocean', Icons.waves, 'Océan'),
                          const SizedBox(width: 12),
                          _buildSoundChip(context, settings, 'thunder', Icons.flash_on, 'Orage'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'De nouveaux sons ambiants seront disponibles bientôt !',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskLink(BuildContext context, TimerProvider timer, TaskProvider taskProvider, bool isDark) {
    final currentTask = timer.currentTask;

    return GestureDetector(
      onTap: () {
        if (timer.isRunning || timer.needsFeedback) return;
        _showTaskSelector(context, timer, taskProvider);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentTask != null ? Icons.task_alt : Icons.assignment_outlined,
              color: currentTask != null ? AppTheme.primaryColor : Theme.of(context).iconTheme.color?.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                currentTask?.title ?? 'Lier une tâche',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: currentTask != null ? null : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!timer.isRunning) ...[
              const SizedBox(width: 12),
              Icon(Icons.keyboard_arrow_down, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
            ]
          ],
        ),
      ),
    );
  }

  void _showTaskSelector(BuildContext context, TimerProvider timer, TaskProvider taskProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lier une tâche', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Aucune tâche'),
                onTap: () {
                  timer.setCurrentTask(null);
                  Navigator.pop(ctx);
                },
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: taskProvider.pendingTasks.length,
                  itemBuilder: (ctx, index) {
                    final task = taskProvider.pendingTasks[index];
                    return ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text(task.title),
                      onTap: () {
                        timer.setCurrentTask(task);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundChip(BuildContext context, SettingsProvider settings, String key, IconData icon, String label) {
    final isSelected = settings.currentSound == key;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        settings.setAmbientSound(key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : (Theme.of(context).brightness == Brightness.dark ? AppTheme.surface2Dark : AppTheme.surface2Light),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Theme.of(context).iconTheme.color?.withOpacity(0.5), size: 20),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, TimerProvider timer, TaskProvider taskProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success),
          const SizedBox(height: 24),
          Text(
            'Session terminée !',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Avez-vous fini la tâche "${timer.currentTask?.title}" ?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    timer.submitFeedback('failed');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Pas fini', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Mark the task as completed globally
                    if (timer.currentTask != null) {
                      taskProvider.toggleTaskStatus(timer.currentTask!.id, false);
                    }
                    timer.submitFeedback('completed');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Oui, terminé', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
