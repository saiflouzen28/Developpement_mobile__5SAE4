import 'package:flutter/material.dart';
import '../../../database/database_helper.dart';
import '../../../models/course.dart';
import 'course_viewer_screen.dart';
import 'package:intl/intl.dart';

class MyPacksScreen extends StatefulWidget {
  const MyPacksScreen({super.key});

  @override
  State<MyPacksScreen> createState() => _MyPacksScreenState();
}

class _MyPacksScreenState extends State<MyPacksScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> userPacks = [];
  bool loading = true;

  // Palette de dégradés pour chaque pack
  final List<List<Color>> packGradients = [
    [Colors.deepPurple.shade400, Colors.deepPurple.shade200],
    [Colors.orange.shade400, Colors.orange.shade200],
    [Colors.green.shade400, Colors.green.shade200],
    [Colors.blue.shade400, Colors.blue.shade200],
    [Colors.red.shade400, Colors.red.shade200],
    [Colors.teal.shade400, Colors.teal.shade200],
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPacks();
  }

  Future<void> _loadUserPacks() async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT up.*, p.title as pack_title, p.duration_days, p.description as pack_description
      FROM user_packs up
      JOIN pack p ON p.id = up.pack_id
      WHERE up.user_id = ?
      ORDER BY up.start_date DESC
    ''', [1]); // userId simulé

    setState(() {
      userPacks = rows;
      loading = false;
    });
  }

  String _formatDate(int epoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch);
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  Future<List<Course>> _loadCoursesForPack(int packId) async {
    final db = await dbHelper.database;
    final pc = await db.query('pack_course', where: 'pack_id = ?', whereArgs: [packId]);
    final ids = pc.map((e) => e['course_id'] as int).toList();
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final q = await db.query('courses', where: 'id IN ($placeholders)', whereArgs: ids);
    return q.map((m) => Course.fromMap(m)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mes packs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: loading
          ? const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple))
          : userPacks.isEmpty
          ? const Center(
        child: Text('Aucun pack acheté',
            style: TextStyle(fontSize: 16, color: Colors.black54)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: userPacks.length,
        itemBuilder: (context, i) {
          final up = userPacks[i];
          final started = _formatDate(up['start_date'] as int);
          final end = _formatDate(up['end_date'] as int);
          final packId = up['pack_id'] as int;

          // Dégradé pour ce pack
          final gradient = packGradients[i % packGradients.length];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre du pack
                  Text(
                    up['pack_title'] ?? 'Pack',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Dates
                  Text(
                    'Valide: $started — $end',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  // Bouton Voir les cours
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final courses = await _loadCoursesForPack(packId);
                        if (courses.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Aucun cours dans ce pack')));
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseViewerScreen(
                                packId: packId, courses: courses),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_circle_outline,
                          color: Colors.white),
                      label: const Text(
                        'Voir les cours',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
