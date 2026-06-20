import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'timer_screen.dart';
import 'tasks_screen.dart';
import 'home_screen.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0; // Default to Home

  final List<Widget> _screens = [
    const HomeScreen(),
    const TimerScreen(),
    const TasksScreen(),
    const StatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch tasks only after the user is authenticated and dashboard loads
    Future.microtask(() => context.read<TaskProvider>().fetchTasks());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppTheme.primaryColor).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard),
                _buildNavItem(1, Icons.timer_outlined, Icons.timer),
                _buildNavItem(2, Icons.list_alt_outlined, Icons.list_alt),
                _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: isSelected
                  ? ShaderMask(
                      key: ValueKey('filled_\$index'),
                      shaderCallback: (Rect bounds) {
                        return AppTheme.primaryGradient.createShader(bounds);
                      },
                      child: Icon(filledIcon, color: Colors.white, size: 28),
                    )
                  : Icon(
                      outlineIcon,
                      key: ValueKey('outline_\$index'),
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      size: 28,
                    ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
