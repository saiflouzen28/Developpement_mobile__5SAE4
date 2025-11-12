import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/quizze_model.dart';
import '../../../models/question_model.dart';
import '../../../database/database_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/email_service.dart';

class StartQuizScreen extends StatefulWidget {
  final Quiz quiz;


  const StartQuizScreen({super.key, required this.quiz});


  @override
  State<StartQuizScreen> createState() => _StartQuizScreenState();
}

class _StartQuizScreenState extends State<StartQuizScreen> {
  List<Question> questions = [];
  int currentIndex = 0;
  int score = 0;
  bool isCountdown = true;
  int countdown = 3;
  String? selectedOption;

  int remainingSeconds = 0;
  Timer? quizTimer;
  
  // 50/50 help feature
  bool fiftyFiftyUsed = false;
  Set<String> removedOptions = {};
  
  // Audience Poll feature
  bool audiencePollUsed = false;
  Map<String, int> pollResults = {};
  
  // Navigation and answer tracking
  Map<int, String> userAnswers = {}; // Store answers for each question index
  bool isReviewMode = false; // Whether user is in review/navigation mode
  
  // Double Points feature (automatically assigned)
  int? doublePointsQuestionIndex;

  @override
  void initState() {
    super.initState();

    // Start the 3-2-1 countdown
    _startCountdown();

    // Load the questions from the database
    _loadQuestions();

    // Initialize timer for the quiz duration (in seconds)
    remainingSeconds = widget.quiz.durationMinutes * 60;
    startTimer();
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }


  void startTimer() {
    quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds == 0) {
        timer.cancel();
        _showResult();
      } else {
        setState(() {
          remainingSeconds--;
        });
      }
    });
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
      
      // Automatically assign a random question for double points
      if (questions.isNotEmpty) {
        final random = DateTime.now().millisecondsSinceEpoch % questions.length;
        doublePointsQuestionIndex = random;
      }
    });
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown == 1) {
        timer.cancel();
        setState(() {
          isCountdown = false;
        });
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  void _showDoublePointsNotification() {
    if (doublePointsQuestionIndex != null && doublePointsQuestionIndex == currentIndex) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🎯 DOUBLE POINTS QUESTION!\nAnswer correctly: +2 points + fix your last mistake!',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.purple.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      });
    }
  }

  void _selectAnswer(String selectedLetter) {
    setState(() {
      selectedOption = selectedLetter;
      userAnswers[currentIndex] = selectedLetter;
    });
  }

  void _goToNextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = userAnswers[currentIndex]; // Restore saved answer if exists
        removedOptions.clear(); // Reset removed options for next question
      });
      _checkAndShowDoublePointsNotification();
    }
  }

  void _goToPreviousQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        selectedOption = userAnswers[currentIndex]; // Restore saved answer if exists
        removedOptions.clear();
      });
      _checkAndShowDoublePointsNotification();
    }
  }
  
  void _checkAndShowDoublePointsNotification() {
    if (doublePointsQuestionIndex == currentIndex) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showDoublePointsNotification();
        }
      });
    }
  }

  void _skipQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = userAnswers[currentIndex];
        removedOptions.clear();
      });
    }
  }

  void _submitQuiz() {
    // Calculate score based on stored answers
    score = 0;
    int? lastWrongQuestionIndex;
    
    for (var entry in userAnswers.entries) {
      final questionIndex = entry.key;
      final userAnswer = entry.value.toUpperCase();
      final correctAnswer = questions[questionIndex].correctOption?.trim().toUpperCase() ?? '';
      
      if (userAnswer == correctAnswer) {
        // Check if this is the double points question
        if (doublePointsQuestionIndex == questionIndex) {
          score += 2; // Double points
          
          // Retroactively correct the most recent wrong answer
          if (lastWrongQuestionIndex != null) {
            score++; // Add point for the previously wrong answer
            lastWrongQuestionIndex = null; // Clear it so it's not counted again
          }
        } else {
          score++; // Normal point
        }
      } else {
        // Track the most recent wrong answer (only if not already corrected)
        if (lastWrongQuestionIndex == null || questionIndex > lastWrongQuestionIndex) {
          lastWrongQuestionIndex = questionIndex;
        }
      }
    }
    _showResult();
  }

  void _useFiftyFifty() {
    if (fiftyFiftyUsed) return;

    final question = questions[currentIndex];
    final correctOption = question.correctOption?.trim().toUpperCase() ?? 'A';
    
    // Get all available options
    List<String> allOptions = ['A'];
    if (question.optionB.isNotEmpty) allOptions.add('B');
    if (question.optionC != null && question.optionC!.isNotEmpty) allOptions.add('C');
    if (question.optionD != null && question.optionD!.isNotEmpty) allOptions.add('D');
    
    // Get incorrect options
    List<String> incorrectOptions = allOptions
        .where((opt) => opt != correctOption)
        .toList();
    
    // Randomly select 2 incorrect options to remove (or 1 if only 1 incorrect available)
    incorrectOptions.shuffle();
    final toRemove = incorrectOptions.take(incorrectOptions.length >= 2 ? 2 : 1).toList();
    
    setState(() {
      fiftyFiftyUsed = true;
      removedOptions.addAll(toRemove);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('50/50 Help Used! Two incorrect answers removed.'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _useAudiencePoll() {
    if (audiencePollUsed) return;

    final question = questions[currentIndex];
    final correctOption = question.correctOption?.trim().toUpperCase() ?? 'A';
    
    // Get all available options (excluding removed ones)
    List<String> allOptions = ['A'];
    if (question.optionB.isNotEmpty) allOptions.add('B');
    if (question.optionC != null && question.optionC!.isNotEmpty) allOptions.add('C');
    if (question.optionD != null && question.optionD!.isNotEmpty) allOptions.add('D');
    
    // Filter out removed options
    allOptions = allOptions.where((opt) => !removedOptions.contains(opt)).toList();
    
    // Generate poll percentages
    Map<String, int> poll = {};
    int remainingPercentage = 100;
    
    // Give the correct answer a higher percentage (50-70%)
    int correctPercentage = 50 + (DateTime.now().millisecond % 21); // Random 50-70
    poll[correctOption] = correctPercentage;
    remainingPercentage -= correctPercentage;
    
    // Distribute remaining percentage among other options
    final otherOptions = allOptions.where((opt) => opt != correctOption).toList();
    
    for (int i = 0; i < otherOptions.length; i++) {
      if (i == otherOptions.length - 1) {
        // Last option gets the remainder
        poll[otherOptions[i]] = remainingPercentage;
      } else {
        // Random distribution for other options
        int percentage = (remainingPercentage * 0.3).toInt() + 
            (DateTime.now().microsecond % 15);
        if (percentage > remainingPercentage - (otherOptions.length - i - 1) * 5) {
          percentage = remainingPercentage - (otherOptions.length - i - 1) * 5;
        }
        poll[otherOptions[i]] = percentage;
        remainingPercentage -= percentage;
      }
    }
    
    setState(() {
      audiencePollUsed = true;
      pollResults = poll;
    });
    
    // Show poll dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.poll_rounded, color: Colors.green.shade600, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Audience Poll Results',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...allOptions.map((option) {
                final percentage = poll[option] ?? 0;
                final optionMap = {
                  'A': question.optionA,
                  'B': question.optionB,
                  'C': question.optionC,
                  'D': question.optionD,
                };
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Option $option',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 24,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              const Text(
                '💡 The audience thinks this is the answer',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResult() {
    quizTimer?.cancel(); // Arrêter le timer
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    double percentage = (score / questions.length) * 100;
    String message;
    Color resultColor;

    if (percentage >= 80) {
      message = "Excellent travail ! 🎉";
      resultColor = Colors.green;
    } else if (percentage >= 50) {
      message = "Bon travail ! Continuez ! 👏";
      resultColor = Colors.orange;
    } else {
      message = "Continuez à apprendre ! 💪";
      resultColor = Colors.red;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              width: 4,
              color: percentage >= 80
                  ? const Color(0xFF10B981)
                  : percentage >= 50
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444),
            ),
            boxShadow: [
              BoxShadow(
                color: (percentage >= 80
                        ? const Color(0xFF10B981)
                        : percentage >= 50
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444))
                    .withOpacity(0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Decorative Header with Gradient
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: percentage >= 80
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : percentage >= 50
                              ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -20,
                        right: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Icon with glow effect
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            percentage >= 80
                                ? Icons.emoji_events_rounded
                                : percentage >= 50
                                    ? Icons.thumb_up_rounded
                                    : Icons.lightbulb_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      // Title with emoji
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            percentage >= 80 ? '🎉' : percentage >= 50 ? '👏' : '💪',
                            style: const TextStyle(fontSize: 44),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              percentage >= 80
                                  ? 'Excellent !'
                                  : percentage >= 50
                                      ? 'Bien joué !'
                                      : 'Continue !',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: percentage >= 80
                                    ? const Color(0xFF10B981)
                                    : percentage >= 50
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Big Score Display with gradient border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: percentage >= 80
                                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                : percentage >= 50
                                    ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                    : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: (percentage >= 80
                                      ? const Color(0xFF10B981)
                                      : percentage >= 50
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444))
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$score',
                                    style: TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: percentage >= 80
                                          ? const Color(0xFF10B981)
                                          : percentage >= 50
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFEF4444),
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      '/${questions.length}',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: percentage >= 80
                                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                        : percentage >= 50
                                            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                            : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (percentage >= 80
                                              ? const Color(0xFF10B981)
                                              : percentage >= 50
                                                  ? const Color(0xFFF59E0B)
                                                  : const Color(0xFFEF4444))
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
              
                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              Icons.check_circle_rounded,
                              'Correct',
                              '$score',
                              const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              Icons.cancel_rounded,
                              'Incorrect',
                              '${questions.length - score}',
                              const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Message with gradient background
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (percentage >= 80
                                      ? const Color(0xFF10B981)
                                      : percentage >= 50
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444))
                                  .withOpacity(0.1),
                              (percentage >= 80
                                      ? const Color(0xFF10B981)
                                      : percentage >= 50
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444))
                                  .withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (percentage >= 80
                                    ? const Color(0xFF10B981)
                                    : percentage >= 50
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444))
                                .withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: percentage >= 80
                                ? const Color(0xFF047857)
                                : percentage >= 50
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFFB91C1C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              
                      const SizedBox(height: 28),
                      
                      // Save Button with gradient
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                percentage >= 80
                                    ? const Color(0xFF10B981)
                                    : percentage >= 50
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444),
                                percentage >= 80
                                    ? const Color(0xFF059669)
                                    : percentage >= 50
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFFDC2626),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: (percentage >= 80
                                        ? const Color(0xFF10B981)
                                        : percentage >= 50
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFEF4444))
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (authProvider.user?.id != null && widget.quiz.id != null) {
                                // Show loading indicator
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('Enregistrement en cours...'),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: Colors.blue.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );

                                // Save to database
                                await DatabaseHelper.saveQuizResult(
                                  userId: authProvider.user!.id!,
                                  quizId: widget.quiz.id!,
                                  score: score,
                                  totalQuestions: questions.length,
                                );
                                
                                // Send email with results
                                bool emailSent = false;
                                if (authProvider.user?.email != null && authProvider.user!.email!.isNotEmpty) {
                                  emailSent = await EmailService.sendQuizResultEmail(
                                    recipientEmail: authProvider.user!.email!,
                                    userName: '${authProvider.user!.prenom} ${authProvider.user!.nom}',
                                    quizTitle: widget.quiz.title,
                                    score: score,
                                    totalQuestions: questions.length,
                                    percentage: percentage,
                                  );
                                }
                                
                                // Show success message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              emailSent 
                                                ? 'Résultats enregistrés et envoyés par email ! ✓' 
                                                : 'Résultats enregistrés ! ✓',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded, size: 24),
                                const SizedBox(width: 12),
                                const Text(
                                  'Enregistrer le résultat',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 14),
                      
                      // Quit Button
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Quitter sans enregistrere',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  @override
  void dispose() {
    quizTimer?.cancel();
    super.dispose();
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if we just started and are on the double points question
    if (!isCountdown && doublePointsQuestionIndex == 0 && currentIndex == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowDoublePointsNotification();
      });
    }

    if (isCountdown) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade400,
                Colors.pink.shade400,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get Ready!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    '$countdown',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = questions[currentIndex];

    // Map letters to options
    final optionMap = {
      'A': question.optionA,
      'B': question.optionB,
      'C': question.optionC,
      'D': question.optionD,
    };

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
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text('Exit Quiz?'),
                              content: const Text('Your progress will be lost'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    quizTimer?.cancel();
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(context); // Exit quiz
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Exit', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.quiz.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.red.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            formatTime(remainingSeconds),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${currentIndex + 1}/${questions.length}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${((currentIndex + 1) / questions.length * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (currentIndex + 1) / questions.length,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Question Card (Scrollable for long questions)
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 280, // Limit height so options are visible
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade400, Colors.blue.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      doublePointsQuestionIndex == currentIndex 
                                          ? Icons.stars_rounded 
                                          : Icons.help_outline_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      doublePointsQuestionIndex == currentIndex
                                          ? 'Question ${currentIndex + 1} 🎯 DOUBLE POINTS'
                                          : 'Question ${currentIndex + 1}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SelectableText(
                                question.questionText,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Help Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 50/50 Help Button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ElevatedButton.icon(
                                onPressed: fiftyFiftyUsed ? null : _useFiftyFifty,
                                icon: Icon(
                                  fiftyFiftyUsed ? Icons.check_circle : Icons.lightbulb_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  fiftyFiftyUsed ? '50/50 ✓' : '50/50',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: fiftyFiftyUsed ? Colors.grey : Colors.amber.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: fiftyFiftyUsed ? 0 : 4,
                                ),
                              ),
                            ),
                          ),
                          // Audience Poll Button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ElevatedButton.icon(
                                onPressed: audiencePollUsed ? null : _useAudiencePoll,
                                icon: Icon(
                                  audiencePollUsed ? Icons.check_circle : Icons.poll_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  audiencePollUsed ? 'Poll ✓' : 'Poll',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: audiencePollUsed ? Colors.grey : Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: audiencePollUsed ? 0 : 4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Options
                      Expanded(
                        child: ListView(
                          children: optionMap.entries
                              .where((entry) => entry.value != null && !removedOptions.contains(entry.key))
                              .map((entry) {
                            final letter = entry.key;
                            final text = entry.value!;
                            final isSelected = selectedOption == letter;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _selectAnswer(letter),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.green.shade400
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.green.shade600
                                            : Colors.purple.shade200,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? Colors.green.withOpacity(0.3)
                                              : Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.purple.shade100,
                                              shape: BoxShape.circle,
                                            ),
                                          child: Center(
                                            child: Text(
                                              letter,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: isSelected
                                                    ? Colors.green.shade600
                                                    : Colors.purple.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              text,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey.shade800,
                                                height: 1.4,
                                              ),
                                              maxLines: null, // Allow unlimited lines
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),

                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      // Navigation Buttons
                      const SizedBox(height: 16),
                      
                      // Submit Button (only show on last question)
                      if (currentIndex == questions.length - 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: userAnswers.isNotEmpty ? _submitQuiz : null,
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: Text(
                                'Submit Quiz (${userAnswers.length}/${questions.length} answered)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: userAnswers.isNotEmpty 
                                    ? Colors.green.shade600 
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: userAnswers.isNotEmpty ? 4 : 0,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom Navigation Arrows
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Arrow
            IconButton(
              onPressed: currentIndex > 0 ? _goToPreviousQuestion : null,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 32,
                color: currentIndex > 0 
                    ? Colors.purple.shade600 
                    : Colors.grey.shade300,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
            ),
            // Next Arrow
            IconButton(
              onPressed: currentIndex < questions.length - 1 ? _goToNextQuestion : null,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 32,
                color: currentIndex < questions.length - 1 
                    ? Colors.purple.shade600 
                    : Colors.grey.shade300,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
