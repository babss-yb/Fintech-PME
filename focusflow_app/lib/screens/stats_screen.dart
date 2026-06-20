import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<PomodoroSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _apiService.getSessions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: FutureBuilder<List<PomodoroSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement des statistiques.'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Aucune session enregistrée.'));
          }

          final sessions = snapshot.data!;
          final Map<int, int> weeklyStats = _calculateWeeklyStats(sessions);
          
          final totalFocusTime = sessions.fold<int>(0, (sum, item) => sum + item.durationMs) ~/ 60000;
          final totalSessions = sessions.length;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Metrics
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Minutes de Focus',
                        value: totalFocusTime.toString(),
                        icon: Icons.local_fire_department,
                        color: AppTheme.secondaryColor,
                        useGradient: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        title: 'Taux de succès',
                        value: totalSessions == 0 
                            ? '0%' 
                            : '\${((sessions.where((s) => s.status == "completed").length / totalSessions) * 100).toStringAsFixed(0)}%',
                        icon: Icons.check_circle_outline,
                        color: AppTheme.success,
                        useGradient: false,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Chart Title
                Text(
                  'Activité des 7 derniers jours',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                // Chart Card
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
                    ),
                  ),
                  height: 300,
                  child: _buildLineChart(weeklyStats),
                ),
                
                const SizedBox(height: 32),
                
                // History Title
                Text(
                  'Historique Récent',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                // History List
                ...sessions.take(10).map((s) => _buildSessionTile(s, isDark)),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<int, int> _calculateWeeklyStats(List<PomodoroSession> sessions) {
    // Return a map of Weekday (1-7, 1=Monday) to total minutes
    final stats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (var session in sessions) {
      if (session.endTime.isAfter(sevenDaysAgo)) {
        final weekday = session.endTime.weekday;
        final minutes = (session.durationMs / 60000).round();
        stats[weekday] = (stats[weekday] ?? 0) + minutes;
      }
    }
    return stats;
  }

  Widget _buildLineChart(Map<int, int> weeklyStats) {
    List<FlSpot> spots = [];
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    
    int maxY = 60; 
    for (int i = 1; i <= 7; i++) {
      int val = weeklyStats[i] ?? 0;
      if (val > maxY) maxY = val + 30;
      spots.add(FlSpot((i - 1).toDouble(), val.toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY.toDouble(),
        minX: 0,
        maxX: 6,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() > 6) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    weekdays[value.toInt()],
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 30,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\${value.toInt()}m',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppTheme.primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Theme.of(context).scaffoldBackgroundColor,
                strokeWidth: 3,
                strokeColor: AppTheme.primaryColor,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.primaryColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(PomodoroSession session, bool isDark) {
    final minutes = (session.durationMs / 60000).round();
    final dateFormatted = DateFormat('dd MMM yyyy à HH:mm').format(session.endTime);

    return Container(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: session.status == 'completed' ? AppTheme.success.withOpacity(0.15) : AppTheme.error.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              session.status == 'completed' ? Icons.check : Icons.close, 
              color: session.status == 'completed' ? AppTheme.success : AppTheme.error, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.task?.title ?? 'Session Libre',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormatted,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '+$minutes min',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
