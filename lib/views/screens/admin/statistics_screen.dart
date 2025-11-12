// lib/views/screens/admin/statistics_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../core/constant/app_theme.dart';
import '../../../database/database_helper.dart';

enum ChartType { eventRevenue, topUsers }

class StatisticsProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Map<String, dynamic>> _eventsPerUser = [];
  List<Map<String, dynamic>> _earningsPerEvent = [];
  bool _isLoading = false;
  ChartType _selectedChart = ChartType.eventRevenue;

  List<Map<String, dynamic>> get eventsPerUser => _eventsPerUser;
  List<Map<String, dynamic>> get earningsPerEvent => _earningsPerEvent;
  bool get isLoading => _isLoading;
  ChartType get selectedChart => _selectedChart;

  StatisticsProvider() {
    loadStatistics();
  }

  void selectChart(ChartType type) {
    _selectedChart = type;
    notifyListeners();
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    notifyListeners();
    try {
      _eventsPerUser = await _db.getEventsPerUser();
      _earningsPerEvent = await _db.getEarningsPerEvent();
    } catch (e) {
      debugPrint('Stats load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NEW: EXPORT TO CSV ---
  Future<String?> exportToCsv(BuildContext context) async {
    try {
      final db = await _db.database;

      // 1. Total Earnings
      final totalRes = await db.rawQuery(
          'SELECT SUM(current_participants * 50) as total FROM events WHERE current_participants > 0');
      final totalEarnings = totalRes.first['total'] as int? ?? 0;

      // 2. Total Users (non-admin)
      final userCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE isAdmin = 0');
      final totalUsers = userCountRes.first['count'] as int;

      // 3. Avg per user
      final avgPerUser = totalUsers > 0 ? (totalEarnings / totalUsers).round() : 0;

      // 4. Events per user
      final usersData = await db.rawQuery('''
        SELECT u.prenom, u.nom, u.email, COUNT(ue.event_id) as events
        FROM users u
        LEFT JOIN user_events ue ON u.id = ue.user_id
        WHERE u.isAdmin = 0
        GROUP BY u.id
        ORDER BY events DESC
      ''');

      // 5. Earnings per event
      final eventsData = await db.rawQuery('''
        SELECT title, category, current_participants, (current_participants * 50) as earnings
        FROM events
        WHERE current_participants > 0
        ORDER BY earnings DESC
      ''');

      // Build CSV
      final csv = <List<dynamic>>[];

      csv.add(['E-Learning Platform Statistics']);
      csv.add(['Generated on', DateTime.now().toString()]);
      csv.add([]);

      csv.add(['SUMMARY']);
      csv.add(['Total Earnings (coins)', totalEarnings]);
      csv.add(['Total Users', totalUsers]);
      csv.add(['Avg Coins per User', avgPerUser]);
      csv.add([]);

      csv.add(['EVENTS PER USER']);
      csv.add(['First Name', 'Last Name', 'Email', 'Events Joined']);
      for (var u in usersData) {
        csv.add([u['prenom'], u['nom'], u['email'], u['events']]);
      }
      csv.add([]);

      csv.add(['EARNINGS PER EVENT']);
      csv.add(['Title', 'Category', 'Participants', 'Earnings (coins)']);
      for (var e in eventsData) {
        csv.add([e['title'], e['category'], e['current_participants'], e['earnings']]);
      }

      final csvString = const ListToCsvConverter().convert(csv);

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/elearning_stats_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  // --------------------------------------------------------------
  //  ANIMATED TOTAL-EARNINGS CARD
  // --------------------------------------------------------------
  Widget _buildTotalEarningsCard(int totalEarnings) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: totalEarnings.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) {
        final displayed = value.toInt();
        return Card(
          elevation: 6,
          color: AppTheme.errorColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 44),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayed.toString(),
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const Text(
                      'Total Platform Earnings (coins)',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------
  //  REVENUE CHART
  // --------------------------------------------------------------
  Widget _buildRevenueChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No revenue yet'));
    }
    final top5 = data.take(5).toList();

    return SizedBox(
      height: 260,
      child: AnimatedBarChart(
        data: top5,
        getY: (m) => (m['earnings'] as int).toDouble(),
        getTooltip: (m) =>
        '${m['title']}\n${m['earnings']} coins\n(${m['current_participants']} × 50)',
        getBottomTitle: (m) {
          final title = m['title'] as String;
          return title.length > 9 ? '${title.substring(0, 9)}…' : title;
        },
        color: AppTheme.primaryColor,
      ),
    );
  }

  // --------------------------------------------------------------
  //  USERS CHART
  // --------------------------------------------------------------
  Widget _buildUserChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No users have joined yet'));
    }
    final top5 = data.take(5).toList();

    return SizedBox(
      height: 260,
      child: AnimatedBarChart(
        data: top5,
        getY: (m) => (m['event_count'] as int).toDouble(),
        getTooltip: (m) =>
        '${m['prenom']} ${m['nom']}\n${m['event_count']} event(s)',
        getBottomTitle: (m) => m['prenom'] as String,
        color: AppTheme.successColor,
      ),
    );
  }

  // --------------------------------------------------------------
  //  SECTION HEADER
  // --------------------------------------------------------------
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 21, fontWeight: FontWeight.bold, color: AppTheme.errorColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatisticsProvider(),
      child: Consumer<StatisticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.errorColor),
              ),
            );
          }

          final totalEarnings = provider.earningsPerEvent.fold<int>(
              0, (sum, e) => sum + (e['earnings'] as int));

          final totalUsers = provider.eventsPerUser.length;
          final avgCoinsPerUser = totalUsers == 0
              ? 0
              : (totalEarnings / totalUsers).round();

          return Scaffold(
            body: RefreshIndicator(
              onRefresh: provider.loadStatistics,
              color: AppTheme.errorColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. TOTAL EARNINGS
                  _buildTotalEarningsCard(totalEarnings),
                  const SizedBox(height: 12),

                  // 2. AVERAGE PER USER
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline,
                          color: AppTheme.primaryColor),
                      title: const Text('Avg. coins per user',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text('$avgCoinsPerUser coins',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. EXPORT BUTTON
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final path = await provider.exportToCsv(context);
                        if (!context.mounted) return;
                        if (path != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Exported: $path'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: 'Copy Path',
                                textColor: Colors.white,
                                onPressed: () {
                                  // Optional: copy to clipboard
                                },
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Export failed'),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text('Export to CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. CHART SELECTOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            provider.selectChart(ChartType.eventRevenue),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          provider.selectedChart == ChartType.eventRevenue
                              ? AppTheme.primaryColor
                              : Colors.grey.shade400,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Event Revenue'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () =>
                            provider.selectChart(ChartType.topUsers),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          provider.selectedChart == ChartType.topUsers
                              ? AppTheme.primaryColor
                              : Colors.grey.shade400,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Top Users'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 5. SECTION TITLE
                  _buildSectionHeader(
                    provider.selectedChart == ChartType.eventRevenue
                        ? 'Top 5 Events by Revenue'
                        : 'Top 5 Users by Events Joined',
                  ),

                  // 6. ANIMATED CHART
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: provider.selectedChart == ChartType.eventRevenue
                        ? _buildRevenueChart(provider.earningsPerEvent)
                        : _buildUserChart(provider.eventsPerUser),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------
//  ANIMATED BAR CHART (GROWING BARS + TOOLTIP)
// --------------------------------------------------------------
class AnimatedBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final double Function(Map<String, dynamic>) getY;
  final String Function(Map<String, dynamic>) getTooltip;
  final String Function(Map<String, dynamic>) getBottomTitle;
  final Color color;

  const AnimatedBarChart({
    super.key,
    required this.data,
    required this.getY,
    required this.getTooltip,
    required this.getBottomTitle,
    required this.color,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  BarChartData _buildBaseChart(bool showFull) {
    final maxY = widget.data.isEmpty
        ? 1.0
        : widget.data.map(widget.getY).reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChartData(
      maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.blueGrey,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
          getTooltipItem: (group, _, rod, _) {
            final item = widget.data[group.x.toInt()];
            return BarTooltipItem(
              widget.getTooltip(item),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, _) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i >= widget.data.length) return const SizedBox.shrink();
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  widget.getBottomTitle(widget.data[i]),
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      barGroups: widget.data.asMap().entries.map((e) {
        final index = e.key;
        final item = e.value;
        final targetY = widget.getY(item);
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: showFull ? targetY : 0,
              color: widget.color,
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final progress = _anim.value;
        final baseChart = _buildBaseChart(progress > 0);

        final animatedGroups = baseChart.barGroups.map((group) {
          return BarChartGroupData(
            x: group.x,
            barRods: group.barRods.map((rod) {
              return BarChartRodData(
                toY: rod.toY * progress,
                color: rod.color,
                width: rod.width,
                borderRadius: rod.borderRadius,
              );
            }).toList(),
          );
        }).toList();

        return BarChart(baseChart.copyWith(barGroups: animatedGroups));
      },
    );
  }
}