import 'package:flutter/material.dart';
import '../../../models/quizze_model.dart';
import '../../../models/question_model.dart';
import '../../../database/database_helper.dart';

class QuizQuestionsScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizQuestionsScreen({super.key, required this.quiz});

  @override
  State<QuizQuestionsScreen> createState() => _QuizQuestionsScreenState();
}

class _QuizQuestionsScreenState extends State<QuizQuestionsScreen> {
  List<Question> questions = [];

  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  String _correctOption = 'A';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [widget.quiz.id],
    );

    setState(() {
      questions = data.map((q) => Question.fromMap(q)).toList();
    });
  }

  Future<void> _addQuestion() async {
    final questionText = _questionController.text.trim();
    final optionA = _optionAController.text.trim();
    final optionB = _optionBController.text.trim();
    final optionC = _optionCController.text.trim();
    final optionD = _optionDController.text.trim();

    if (questionText.isEmpty || optionA.isEmpty || optionB.isEmpty) return;

    final question = Question(
      quizId: widget.quiz.id!,
      questionText: questionText,
      optionA: optionA,
      optionB: optionB,
      optionC: optionC.isEmpty ? null : optionC,
      optionD: optionD.isEmpty ? null : optionD,
      correctOption: _correctOption,
      createdAt: DateTime.now(),
    );

    final db = await DatabaseHelper.instance.database;
    await db.insert('questions', question.toMap());

    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();

    _loadQuestions();
  }

  Future<void> _deleteQuestion(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions for "${widget.quiz.title}"'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add question form
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question Text'),
            ),
            TextField(
              controller: _optionAController,
              decoration: const InputDecoration(labelText: 'Option A'),
            ),
            TextField(
              controller: _optionBController,
              decoration: const InputDecoration(labelText: 'Option B'),
            ),
            TextField(
              controller: _optionCController,
              decoration: const InputDecoration(labelText: 'Option C (optional)'),
            ),
            TextField(
              controller: _optionDController,
              decoration: const InputDecoration(labelText: 'Option D (optional)'),
            ),
            DropdownButton<String>(
              value: _correctOption,
              items: ['A', 'B', 'C', 'D']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _correctOption = val);
              },
            ),
            ElevatedButton(
              onPressed: _addQuestion,
              child: const Text('Add Question'),
            ),
            const SizedBox(height: 16),

            // Questions list
            Expanded(
              child: questions.isEmpty
                  ? const Center(child: Text('No questions yet'))
                  : ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  return Card(
                    child: ListTile(
                      title: Text(q.questionText),
                      subtitle: Text(
                          'Correct: ${q.correctOption}, Options: ${q.optionA}, ${q.optionB}${q.optionC != null ? ', ${q.optionC}' : ''}${q.optionD != null ? ', ${q.optionD}' : ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteQuestion(q.id!),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
