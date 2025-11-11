import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/statistics_service.dart';

class AdminStatsScreen extends StatefulWidget {
  final StatisticsService statsService;
  const AdminStatsScreen({super.key, required this.statsService});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  String filter = 'jour';
  List<PackStats> stats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => isLoading = true);

    DateTime now = DateTime.now();
    DateTime start, end;

    switch (filter) {
      case 'jour':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'mois':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'année':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      default:
        start = DateTime(2000);
        end = DateTime.now();
    }

    final data = await widget.statsService.getStats(start: start, end: end);
    setState(() {
      stats = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : Column(
        children: [
          // 🔹 Filtre période
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: filter,
                underline: const SizedBox(),
                isExpanded: true,
                items: ['jour', 'mois', 'année']
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e[0].toUpperCase() + e.substring(1),
                    style: const TextStyle(fontSize: 16),
                  ),
                ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    filter = v!;
                  });
                  _loadStats();
                },
              ),
            ),
          ),

          // 🔹 Graphique des revenus
          if (stats.isNotEmpty)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildChart(),
                  ),
                ),
              ),
            ),

          // 🔹 Liste des packs
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final item = stats[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    tileColor: Colors.white,
                    title: Text(
                      item.titre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),
                    ),
                    subtitle: Text(
                        "Achats: ${item.totalAchats} • Revenus: ${item.revenus} DT",
                        style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final users =
                      await widget.statsService.getUsersByPack(item.id);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("Utilisateurs ayant acheté ${item.titre}"),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView(
                              shrinkWrap: true,
                              children: users
                                  .map((u) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text("${u['nom']} - ${u['email']}"),
                              ))
                                  .toList(),
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'))
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Graphique barre des revenus par pack
  Widget _buildChart() {
    double maxY = stats.map((e) => e.revenus).fold<double>(0, (prev, e) => e > prev ? e : prev);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + 50,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < stats.length) {
                  return Text(stats[index].titre,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: 50),
          ),
        ),
        barGroups: List.generate(stats.length, (i) {
          final colors = [Colors.deepPurple, Colors.orange, Colors.green, Colors.blue, Colors.red];
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: stats[i].revenus,
              color: colors[i % colors.length],
              width: 22,
              borderRadius: BorderRadius.circular(6),
            ),
          ]);
        }),
      ),
    );
  }
}
