import 'package:elearning_events_app/views/screens/quizze/start_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/quizze_model.dart';
import '../../../models/question_model.dart';
import '../../../providers/questionsprovider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QuizDetailScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizDetailScreen({super.key, required this.quiz});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  List<Question> questions = [];

  final questionTextController = TextEditingController();
  final optionAController = TextEditingController();
  final optionBController = TextEditingController();
  final optionCController = TextEditingController();
  final optionDController = TextEditingController();
  String? correctOption;

  @override
  void initState() {
    super.initState();
    // Load questions after first frame to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  Future<void> _loadQuestions() async {
    final questionsProvider = Provider.of<QuestionsProvider>(context, listen: false);
    await questionsProvider.loadQuestions(widget.quiz.id!);
    if (!mounted) return;
    setState(() {
      questions = questionsProvider.questions;
    });
  }

  void _showAddQuestionDialog() {
    final questionsProvider = Provider.of<QuestionsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context2, setState2) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.purple.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with gradient
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.blue.shade400],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.help_rounded, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Add New Question',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildDialogTextField(
                      questionTextController,
                      'Question',
                      Icons.quiz_rounded,
                      'Enter your question here',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDialogTextField(
                      optionAController,
                      'Option A',
                      Icons.looks_one_rounded,
                      'Enter option A',
                    ),
                    const SizedBox(height: 12),
                    
                    _buildDialogTextField(
                      optionBController,
                      'Option B',
                      Icons.looks_two_rounded,
                      'Enter option B',
                    ),
                    const SizedBox(height: 12),
                    
                    _buildDialogTextField(
                      optionCController,
                      'Option C (Optional)',
                      Icons.looks_3_rounded,
                      'Enter option C',
                    ),
                    const SizedBox(height: 12),
                    
                    _buildDialogTextField(
                      optionDController,
                      'Option D (Optional)',
                      Icons.looks_4_rounded,
                      'Enter option D',
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: correctOption,
                        items: ['A', 'B', 'C', 'D']
                            .map((opt) => DropdownMenuItem(
                                  value: opt,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green.shade400,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Option $opt'),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState2(() => correctOption = value),
                        decoration: InputDecoration(
                          labelText: 'Correct Answer',
                          labelStyle: TextStyle(color: Colors.purple.shade700),
                          prefixIcon: Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.purple.shade400,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple.shade400, Colors.blue.shade400],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded, color: Colors.white),
                              label: const Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                if (questionTextController.text.isEmpty || correctOption == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.warning_rounded, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text('Please fill all required fields'),
                                        ],
                                      ),
                                      backgroundColor: Colors.orange.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final newQuestion = Question(
                                  quizId: widget.quiz.id!,
                                  questionText: questionTextController.text,
                                  optionA: optionAController.text,
                                  optionB: optionBController.text,
                                  optionC: optionCController.text.isEmpty
                                      ? null
                                      : optionCController.text,
                                  optionD: optionDController.text.isEmpty
                                      ? null
                                      : optionDController.text,
                                  correctOption: correctOption!,
                                );

                                await questionsProvider.addQuestion(newQuestion);
                                await _loadQuestions();

                                // Clear controllers
                                questionTextController.clear();
                                optionAController.clear();
                                optionBController.clear();
                                optionCController.clear();
                                optionDController.clear();
                                correctOption = null;

                                Navigator.pop(context);
                                
                                // Success feedback
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Question added successfully!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// Helper method for text fields
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.purple.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.purple.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.blue.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Custom App Bar with Back Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.purple.shade700,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Quiz Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Quiz Hero Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          // Icon with background
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 56,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            quiz.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            quiz.description ?? "No description available.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Info Chips Grid
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (quiz.category != null)
                                _buildInfoChip(Icons.category_rounded, quiz.category!),
                              if (quiz.difficulty != null)
                                _buildInfoChip(_getDifficultyIcon(quiz.difficulty), quiz.difficulty!),
                              _buildInfoChip(Icons.help_outline_rounded, '${questions.length} Questions'),
                              _buildInfoChip(Icons.timer_rounded, '${quiz.durationMinutes} min'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


                
                const SizedBox(height: 24),

                // QR Code Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.purple.shade600,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Scan to Start Quiz",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.purple.shade100,
                                width: 2,
                              ),
                            ),
                            child: QrImageView(
                              data: "quiz_${quiz.id}",
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.grey.shade50,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.purple.shade700,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.circle,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tag_rounded,
                                  color: Colors.purple.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Quiz ID: ${quiz.id}",
                                  style: TextStyle(
                                    color: Colors.purple.shade700,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Start Quiz Button (Primary)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: questions.isEmpty
                              ? null
                              : LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.teal.shade400,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: questions.isEmpty
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_rounded, color: Colors.white, size: 28),
                          label: const Text(
                            "Start Quiz",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: questions.isEmpty
                                ? Colors.grey.shade300
                                : Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: questions.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StartQuizScreen(quiz: quiz),
                                    ),
                                  );
                                },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Add Question Button (Secondary)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.purple.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.add_circle_rounded,
                            color: Colors.purple.shade600,
                            size: 28,
                          ),
                          label: Text(
                            "Add Question",
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _showAddQuestionDialog,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDifficultyIcon(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return Icons.trending_down_rounded;
      case 'hard':
        return Icons.trending_up_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
