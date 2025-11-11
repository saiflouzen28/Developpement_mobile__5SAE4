import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/quizze_model.dart';
import '../../../models/question_model.dart';
import '../../../providers/quizzes_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../database/database_helper.dart';
import '../../../core/ai_service.dart';

class ManageQuizzesScreen extends StatefulWidget {
  const ManageQuizzesScreen({super.key});

  @override
  State<ManageQuizzesScreen> createState() => _ManageQuizzesScreenState();
}

class _ManageQuizzesScreenState extends State<ManageQuizzesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizzesProvider>(context, listen: false).loadQuizzes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizzesProvider = Provider.of<QuizzesProvider>(context);
    final quizzes = quizzesProvider.quizzes;

    final filteredQuizzes = quizzes.where((quiz) {
      final search = _searchController.text.toLowerCase();
      return quiz.title.toLowerCase().contains(search) ||
          (quiz.description?.toLowerCase().contains(search) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search quizzes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Quiz List
          Expanded(
            child: quizzesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredQuizzes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No quizzes yet'
                                  : 'No quizzes found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create a quiz',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredQuizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = filteredQuizzes[index];
                          return _buildQuizCard(context, quiz, quizzesProvider);
                        },
                      ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateQuizOptions(context, quizzesProvider),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateQuizOptions(BuildContext context, QuizzesProvider quizzesProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('Create Quiz Manually'),
              onTap: () {
                Navigator.pop(context);
                _showAddQuizDialog(context, quizzesProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: const Text('Create Quiz with AI'),
              subtitle: const Text('Generate questions automatically'),
              onTap: () {
                Navigator.pop(context);
                _showCreateWithAiDialog(context, quizzesProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, Quiz quiz, QuizzesProvider quizzesProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showQuizDetails(context, quiz),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Quiz'),
                            content: Text('Delete "${quiz.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && quiz.id != null) {
                          await quizzesProvider.deleteQuiz(quiz.id!);
                        }
                      } else if (value == 'edit') {
                        _showEditQuizDialog(context, quiz, quizzesProvider);
                      }
                    },
                  ),
                ],
              ),
              if (quiz.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  quiz.description!,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(Icons.help_outline, '${quiz.totalQuestions} questions'),
                  _buildChip(Icons.timer, '${quiz.durationMinutes} min'),
                  _buildChip(Icons.category, quiz.category ?? 'General'),
                  _buildChip(Icons.trending_up, quiz.difficulty ?? 'Medium'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showQuizDetails(BuildContext context, Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizManageDetailScreen(quiz: quiz),
      ),
    );
  }

  // Add Quiz Dialog (Manual)
  void _showAddQuizDialog(BuildContext context, QuizzesProvider quizzesProvider) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final totalQuestionsController = TextEditingController();
    final durationController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    String selectedCategory = 'Technology';
    String selectedDifficulty = 'Medium';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Quiz'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Quiz Title'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: totalQuestionsController,
                    decoration: const InputDecoration(labelText: 'Total Questions'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      return n == null || n < 1 ? 'Min 1' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      return n == null || n < 1 ? 'Min 1' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Technology', 'Science', 'AI', 'Web Development', 'Other']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDifficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedDifficulty = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) return;

                final newQuiz = Quiz(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  totalQuestions: int.parse(totalQuestionsController.text.trim()),
                  durationMinutes: int.parse(durationController.text.trim()),
                  category: selectedCategory,
                  difficulty: selectedDifficulty,
                  createdBy: Provider.of<AuthProvider>(context, listen: false).user?.id ?? 1,
                  createdAt: DateTime.now(),
                );

                await quizzesProvider.addQuiz(newQuiz);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // Edit Quiz Dialog
  void _showEditQuizDialog(BuildContext context, Quiz quiz, QuizzesProvider quizzesProvider) {
    final titleController = TextEditingController(text: quiz.title);
    final descriptionController = TextEditingController(text: quiz.description);
    final totalQuestionsController = TextEditingController(text: quiz.totalQuestions.toString());
    final durationController = TextEditingController(text: quiz.durationMinutes.toString());
    final _formKey = GlobalKey<FormState>();

    // Define available categories
    final availableCategories = ['Technology', 'Science', 'AI', 'Web Development', 'Other'];
    final availableDifficulties = ['Easy', 'Medium', 'Hard'];
    
    // Ensure the quiz's current category is in the list, or default to 'Technology'
    String selectedCategory = quiz.category != null && availableCategories.contains(quiz.category)
        ? quiz.category!
        : 'Technology';
    
    // Ensure the quiz's current difficulty is in the list, or default to 'Medium'
    String selectedDifficulty = quiz.difficulty != null && availableDifficulties.contains(quiz.difficulty)
        ? quiz.difficulty!
        : 'Medium';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Quiz'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Quiz Title'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: totalQuestionsController,
                    decoration: const InputDecoration(labelText: 'Total Questions'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      return n == null || n < 1 ? 'Min 1' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      return n == null || n < 1 ? 'Min 1' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: availableCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDifficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: availableDifficulties
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedDifficulty = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) return;

                final updatedQuiz = Quiz(
                  id: quiz.id,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  totalQuestions: int.parse(totalQuestionsController.text.trim()),
                  durationMinutes: int.parse(durationController.text.trim()),
                  category: selectedCategory,
                  difficulty: selectedDifficulty,
                  createdBy: quiz.createdBy,
                  createdAt: quiz.createdAt,
                );

                // Update quiz in database
                final db = await DatabaseHelper.instance.database;
                await db.update('quizzes', updatedQuiz.toMap(), where: 'id = ?', whereArgs: [quiz.id]);
                
                await quizzesProvider.loadQuizzes();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Create Quiz with AI Dialog
  void _showCreateWithAiDialog(BuildContext context, QuizzesProvider quizzesProvider) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final totalQuestionsController = TextEditingController(text: '10');
    final durationController = TextEditingController(text: '15');
    final _formKey = GlobalKey<FormState>();

    String selectedCategory = 'Technology';
    String selectedDifficulty = 'Medium';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome_rounded),
              SizedBox(width: 8),
              Text('Create Quiz with AI'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Quiz Topic'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description/Prompt'),
                    maxLines: 3,
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: totalQuestionsController,
                    decoration: const InputDecoration(labelText: 'Number of Questions'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      return n == null || n < 4 ? 'Min 4' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      return n == null || n < 5 ? 'Min 5' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Technology', 'Science', 'AI', 'Web Development', 'Other']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDifficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedDifficulty = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Generate'),
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) return;

                final title = titleController.text.trim();
                final desc = descriptionController.text.trim();
                final totalQ = int.parse(totalQuestionsController.text.trim());
                final duration = int.parse(durationController.text.trim());

                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final generated = await generateQuestionsFromAi(
                    topic: title,
                    description: desc,
                    totalQuestions: totalQ,
                    difficulty: selectedDifficulty,
                  );

                  final quizMap = {
                    'title': title,
                    'description': desc,
                    'total_questions': totalQ,
                    'duration_minutes': duration,
                    'category': selectedCategory,
                    'difficulty': selectedDifficulty,
                    'created_by': Provider.of<AuthProvider>(context, listen: false).user?.id ?? 1,
                    'created_at': DateTime.now().toIso8601String(),
                  };

                  final quizId = await DatabaseHelper.instance.addQuizReturnId(quizMap);
                  if (quizId == null) throw Exception('Failed to create quiz');

                  for (final q in generated) {
                    await DatabaseHelper.instance.addQuestion({
                      'quiz_id': quizId,
                      'question_text': q['question_text'] ?? '',
                      'option_a': q['option_a'] ?? '',
                      'option_b': q['option_b'] ?? '',
                      'option_c': q['option_c'] ?? '',
                      'option_d': q['option_d'] ?? '',
                      'correct_option': q['correct_option'] ?? 'A',
                    });
                  }

                  Navigator.pop(context); // Close progress
                  await quizzesProvider.loadQuizzes();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Quiz created with AI!')),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context); // Close progress
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Quiz Detail/Management Screen
class _QuizManageDetailScreen extends StatefulWidget {
  final Quiz quiz;

  const _QuizManageDetailScreen({required this.quiz});

  @override
  State<_QuizManageDetailScreen> createState() => _QuizManageDetailScreenState();
}

class _QuizManageDetailScreenState extends State<_QuizManageDetailScreen> {
  List<Question> questions = [];
  bool isLoading = true;

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
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddQuestionDialog(),
            tooltip: 'Add Question',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No questions yet'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                        onPressed: () => _showAddQuestionDialog(),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text('Question ${index + 1}'),
                        subtitle: Text(
                          question.questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showEditQuestionDialog(question),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _deleteQuestion(question),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(question.questionText,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                _buildOption('A', question.optionA, question.correctOption == 'A'),
                                _buildOption('B', question.optionB, question.correctOption == 'B'),
                                if (question.optionC != null)
                                  _buildOption('C', question.optionC!, question.correctOption == 'C'),
                                if (question.optionD != null)
                                  _buildOption('D', question.optionD!, question.correctOption == 'D'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildOption(String letter, String text, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: isCorrect ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showAddQuestionDialog() {
    final questionController = TextEditingController();
    final optionAController = TextEditingController();
    final optionBController = TextEditingController();
    final optionCController = TextEditingController();
    final optionDController = TextEditingController();
    String correctOption = 'A';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Question'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: questionController,
                    decoration: const InputDecoration(labelText: 'Question Text'),
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: optionAController,
                    decoration: const InputDecoration(labelText: 'Option A'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: optionBController,
                    decoration: const InputDecoration(labelText: 'Option B'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: optionCController,
                    decoration: const InputDecoration(labelText: 'Option C (Optional)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: optionDController,
                    decoration: const InputDecoration(labelText: 'Option D (Optional)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: correctOption,
                    decoration: const InputDecoration(labelText: 'Correct Option'),
                    items: ['A', 'B', 'C', 'D']
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) => setState(() => correctOption = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final question = Question(
                  quizId: widget.quiz.id!,
                  questionText: questionController.text.trim(),
                  optionA: optionAController.text.trim(),
                  optionB: optionBController.text.trim(),
                  optionC: optionCController.text.trim().isEmpty
                      ? null
                      : optionCController.text.trim(),
                  optionD: optionDController.text.trim().isEmpty
                      ? null
                      : optionDController.text.trim(),
                  correctOption: correctOption,
                  createdAt: DateTime.now(),
                );

                await DatabaseHelper.instance.addQuestion(question.toMap());
                await _loadQuestions();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuestionDialog(Question question) {
    final questionController = TextEditingController(text: question.questionText);
    final optionAController = TextEditingController(text: question.optionA);
    final optionBController = TextEditingController(text: question.optionB);
    final optionCController = TextEditingController(text: question.optionC ?? '');
    final optionDController = TextEditingController(text: question.optionD ?? '');
    String correctOption = question.correctOption ?? 'A';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Question'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: questionController,
                    decoration: const InputDecoration(labelText: 'Question Text'),
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: optionAController,
                    decoration: const InputDecoration(labelText: 'Option A'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: optionBController,
                    decoration: const InputDecoration(labelText: 'Option B'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: optionCController,
                    decoration: const InputDecoration(labelText: 'Option C (Optional)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: optionDController,
                    decoration: const InputDecoration(labelText: 'Option D (Optional)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: correctOption,
                    decoration: const InputDecoration(labelText: 'Correct Option'),
                    items: ['A', 'B', 'C', 'D']
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) => setState(() => correctOption = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final db = await DatabaseHelper.instance.database;
                await db.update(
                  'questions',
                  {
                    'question_text': questionController.text.trim(),
                    'option_a': optionAController.text.trim(),
                    'option_b': optionBController.text.trim(),
                    'option_c': optionCController.text.trim().isEmpty
                        ? null
                        : optionCController.text.trim(),
                    'option_d': optionDController.text.trim().isEmpty
                        ? null
                        : optionDController.text.trim(),
                    'correct_option': correctOption,
                  },
                  where: 'id = ?',
                  whereArgs: [question.id],
                );

                await _loadQuestions();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && question.id != null) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('questions', where: 'id = ?', whereArgs: [question.id]);
      await _loadQuestions();
    }
  }
}
