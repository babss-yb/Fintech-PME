import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_checkbox.dart';
import '../widgets/priority_chip.dart';
import '../widgets/gradient_button.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'Toutes';

  List<Task> _getFilteredTasks(TaskProvider provider) {
    switch (_filter) {
      case 'En cours':
        return provider.pendingTasks;
      case 'Complétées':
        return provider.completedTasks;
      case 'Haute priorité':
        return provider.tasks.where((t) => t.priority == 'high').toList();
      case 'Toutes':
      default:
        return provider.tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = _getFilteredTasks(taskProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Tâches')),
      body: Column(
        children: [
          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Toutes'),
                const SizedBox(width: 8),
                _buildFilterChip('En cours'),
                const SizedBox(width: 8),
                _buildFilterChip('Complétées'),
                const SizedBox(width: 8),
                _buildFilterChip('Haute priorité'),
              ],
            ),
          ),
          
          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune tâche correspondante.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _SlideInItem(
                            index: index,
                            child: _buildTaskCard(task, taskProvider, isDark),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddTaskBottomSheet(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.surface2Dark : AppTheme.surface2Light),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, TaskProvider taskProvider, bool isDark) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) {
        taskProvider.deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tâche supprimée'),
            action: SnackBarAction(
              label: 'Annuler',
              textColor: Colors.white,
              onPressed: () {
                // Future: implement undo
              },
            ),
            backgroundColor: AppTheme.surface2Dark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: task.isCompleted ? 0.6 : 1.0,
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedCheckbox(
                value: task.isCompleted,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  taskProvider.toggleTaskStatus(task.id, task.isCompleted);
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? Theme.of(context).textTheme.bodySmall?.color : null,
                          ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PriorityChip(priority: task.priority),
                  const SizedBox(height: 8),
                  Icon(Icons.more_horiz, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddTaskSheet(),
    );
  }
}

// Custom manual staggered animation wrapper
class _SlideInItem extends StatefulWidget {
  final Widget child;
  final int index;

  const _SlideInItem({required this.child, required this.index});

  @override
  State<_SlideInItem> createState() => _SlideInItemState();
}

class _SlideInItemState extends State<_SlideInItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle tâche', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: Theme.of(context).textTheme.titleMedium,
              decoration: InputDecoration(
                hintText: 'Que devez-vous faire ?',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ),
            const Divider(),
            TextField(
              controller: _descCtrl,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Description (optionnel)',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                icon: Icon(Icons.notes, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Priorité', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPrioritySelector('low', 'Basse', AppTheme.success),
                const SizedBox(width: 12),
                _buildPrioritySelector('medium', 'Moyenne', AppTheme.warning),
                const SizedBox(width: 12),
                _buildPrioritySelector('high', 'Haute', AppTheme.error),
              ],
            ),
            const SizedBox(height: 32),
            GradientButton(
              text: 'Créer la tâche',
              onPressed: () {
                if (_titleCtrl.text.trim().isNotEmpty) {
                  context.read<TaskProvider>().addTask(
                        _titleCtrl.text.trim(),
                        priority: _priority,
                      );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(String value, String label, Color color) {
    final isSelected = _priority == value;
    return GestureDetector(
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
