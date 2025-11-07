import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../database/database_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/quizzes_provider.dart';
import '../../../models/quizze_model.dart';
import 'package:intl/intl.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  void _reload() {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    setState(() {
      if (userId != null) {
        _historyFuture = DatabaseHelper.getUserQuizResults(userId);
      } else {
        _historyFuture = Future.value([]);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    if (userId != null) {
      _historyFuture = DatabaseHelper.getUserQuizResults(userId);
    } else {
      _historyFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzesProvider = Provider.of<QuizzesProvider>(context);
    final quizzes = quizzesProvider.quizzes;

  Widget _buildPercentageBadge(double percentage, bool passed) {
    final intPct = percentage.round();
    final colors = passed
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [const Color(0xFFEF4444), const Color(0xFFDC2626)];

    return Container(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors),
              boxShadow: [BoxShadow(color: colors.first.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Text('$intPct%', style: TextStyle(fontWeight: FontWeight.bold, color: colors.first, fontSize: 14)),
          ),
        ],
      ),
    );
  }

    return Scaffold(
      body: Column(
        children: [
          // Modern gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.blue.shade400]),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quiz History', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _historyFuture,
                        builder: (context, snap) {
                          final count = snap.hasData ? snap.data!.length : 0;
                          return Text('$count results', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14));
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _reload,
                  tooltip: 'Refresh',
                )
              ],
            ),
          ),
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 80),
                        Icon(Icons.history_rounded, size: 96, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Center(child: Text('No quiz history found', style: TextStyle(fontSize: 18, color: Colors.grey.shade700))),
                      ],
                    );
                  }

                  final results = snapshot.data!;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = results[index];
                      final quizId = r['quiz_id'] as int?;
                      final quiz = quizzes.firstWhere(
                        (q) => q.id == quizId,
                        orElse: () => Quiz(id: quizId, title: 'Quiz #$quizId', description: null, totalQuestions: r['total_questions'] ?? 0, durationMinutes: r['duration'] ?? 0),
                      );

                      final score = r['score'] ?? 0;
                      final percentage = (r['percentage'] is double) ? r['percentage'] : (r['percentage'] as num).toDouble();
                      final passed = (r['passed'] == 1);
                      final takenAt = r['taken_at'] != null ? DateTime.parse(r['taken_at']) : null;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: _buildPercentageBadge(percentage, passed),
                          title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text('Score: $score / ${quiz.totalQuestions}', style: TextStyle(color: Colors.grey.shade800)),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(passed ? 'Passed' : 'Failed', style: TextStyle(color: passed ? Colors.green.shade800 : Colors.red.shade800)),
                                    backgroundColor: passed ? Colors.green.shade50 : Colors.red.shade50,
                                  ),
                                ],
                              ),
                              if (takenAt != null) Text(DateFormat('yyyy-MM-dd • HH:mm').format(takenAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                          trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                          onTap: () {
                            // Optionally navigate to a detail view for this result
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
