import 'package:elearning_events_app/views/screens/quizze/quiz_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/app_theme.dart';
import '../../../models/quizze_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/events_provider.dart';
import '../../../providers/quizzes_provider.dart';
import 'package:intl/intl.dart';
import '../../../core/ai_service.dart';
import '../../../core/constants.dart';
import '../../../database/database_helper.dart';
import 'quiz_history_screen.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventsProvider>(context, listen: false).loadEvents();
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
    final authProvider = Provider.of<AuthProvider>(context);
    final quizzesProvider = Provider.of<QuizzesProvider>(context);
    final quizzes = quizzesProvider.quizzes;

    // Filter quizzes by search input
    final filteredQuizzes = quizzes.where((quiz) {
      final search = _searchController.text.toLowerCase();
      return quiz.title.toLowerCase().contains(search) ||
          (quiz.description?.toLowerCase().contains(search) ?? false);
    }).toList();

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Back Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
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
                            tooltip: 'Back',
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title and subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, ${authProvider.user?.prenom ?? 'User'} 👋',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ready to test your knowledge?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // User Avatar
                        Row(
                          children: [
                            Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade400,
                                Colors.blue.shade400,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Text(
                              authProvider.user?.prenom?.substring(0, 1).toUpperCase() ?? 'U',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                            ),
                            const SizedBox(width: 12),
                            // History button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.history_rounded, color: Colors.purple.shade700),
                                tooltip: 'History',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const QuizHistoryScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar with modern design
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search for quizzes...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.purple.shade400, size: 28),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Quizzes List
              Expanded(
                child: quizzesProvider.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading quizzes...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredQuizzes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No quizzes found',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Start creating your first quiz!'
                                      : 'Try a different search term',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredQuizzes.length,
                            itemBuilder: (context, index) {
                              final quiz = filteredQuizzes[index];
                              final colors = _getGradientColors(index);
                              
                              return _buildQuizCard(
                                context,
                                quiz,
                                colors,
                                quizzesProvider,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade400,
              Colors.blue.shade400,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            builder: (_) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_rounded),
                    title: const Text('Create Quiz Manually'),
                    onTap: () {
                      Navigator.pop(context);
                      showAddQuizDialog(context, quizzesProvider);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_rounded),
                    title: const Text('Create Quiz with AI'),
                    subtitle: const Text('Generate questions automatically from topic & description'),
                    onTap: () {
                      Navigator.pop(context);
                      showCreateWithAiDialog(context, quizzesProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(int index) {
    final gradients = [
      [Color(0xFF667eea), Color(0xFF764ba2)],
      [Color(0xFFf093fb), Color(0xFFf5576c)],
      [Color(0xFF4facfe), Color(0xFF00f2fe)],
      [Color(0xFF43e97b), Color(0xFF38f9d7)],
      [Color(0xFFfa709a), Color(0xFFfee140)],
      [Color(0xFF30cfd0), Color(0xFF330867)],
    ];
    return gradients[index % gradients.length];
  }

  Widget _buildQuizCard(
    BuildContext context,
    Quiz quiz,
    List<Color> gradientColors,
    QuizzesProvider quizzesProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientColors[0],
                gradientColors[1],
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizDetailScreen(quiz: quiz),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.quiz_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quiz.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  quiz.category ?? 'General',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.white),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Row(
                                  children: const [
                                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Delete Quiz'),
                                  ],
                                ),
                                content: Text('Are you sure you want to delete "${quiz.title}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await quizzesProvider.deleteQuiz(quiz.id!);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      quiz.description ?? 'No description available.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          Icons.access_time_rounded,
                          '${quiz.durationMinutes} min',
                        ),
                        _buildInfoChip(
                          Icons.help_outline_rounded,
                          '${quiz.totalQuestions} questions',
                        ),
                        _buildInfoChip(
                          _getDifficultyIcon(quiz.difficulty),
                          quiz.difficulty ?? 'Medium',
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
  void showAddQuizDialog(BuildContext context, QuizzesProvider quizzesProvider) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final totalQuestionsController = TextEditingController();
    final durationController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    String selectedCategory = 'Technology';
    String selectedDifficulty = 'Medium';
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
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
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          Icon(Icons.quiz_rounded, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'New Quiz',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    _buildTextField(
                      controller: titleController,
                      label: 'Quiz Title',
                      icon: Icons.title_rounded,
                      hint: 'Enter quiz title',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Title is required';
                        if (val.trim().length < 3) return 'Title must be at least 3 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Description',
                      icon: Icons.description_rounded,
                      hint: 'Enter quiz description',
                      maxLines: 3,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Description is required';
                        if (val.trim().length < 10) return 'Description must be at least 10 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Total Questions and Duration in Row
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(
                            controller: totalQuestionsController,
                            label: 'Questions',
                            icon: Icons.format_list_numbered_rounded,
                            hint: '10',
                            keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Total questions is required';
                              final n = int.tryParse(val.trim());
                              if (n == null || n < 10) return 'Enter a valid number (minimum 10)';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: durationController,
                            label: 'Minutes',
                            icon: Icons.timer_rounded,
                            hint: '15',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Duration is required';
                              final n = int.tryParse(val.trim());
                              if (n == null || n < 10) return 'Duration must be at least 10 minutes';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: [
                          'Technology',
                          'Design',
                          'Market',
                          'Science',
                          'AI',
                          'Web '
                        ].map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                            .toList(),
                        onChanged: (value) => setState(() => selectedCategory = value!),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(color: Colors.purple.shade700),
                          prefixIcon: Icon(Icons.category_rounded, color: Colors.purple.shade400),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Difficulty with visual indicators
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedDifficulty,
                        items: ['Easy', 'Medium', 'Hard']
                            .map((diff) => DropdownMenuItem(
                                  value: diff,
                                  child: Row(
                                    children: [
                                      Icon(
                                        diff == 'Easy'
                                            ? Icons.trending_down_rounded
                                            : diff == 'Hard'
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_flat_rounded,
                                        color: diff == 'Easy'
                                            ? Colors.green
                                            : diff == 'Hard'
                                                ? Colors.red
                                                : Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(diff),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => selectedDifficulty = value!),
                        decoration: InputDecoration(
                          labelText: 'Difficulty',
                          labelStyle: TextStyle(color: Colors.purple.shade700),
                          prefixIcon: Icon(Icons.bar_chart_rounded, color: Colors.purple.shade400),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Created Date
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.purple.shade400,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: Colors.purple.shade400),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Created Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMMM dd, yyyy').format(selectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                              'Cancell',
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
                                'Create Quiz',
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
                                // Validate form
                                if (!(_formKey.currentState?.validate() ?? false)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Please fix the errors in the form'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }
                                final title = titleController.text.trim();
                                final desc = descriptionController.text.trim();
                                final totalQ = int.tryParse(totalQuestionsController.text.trim()) ?? 0;
                                final duration = int.tryParse(durationController.text.trim()) ?? 0;

                                final newQuiz = Quiz(
                                  title: titleController.text.trim(),
                                  description: descriptionController.text.trim(),
                                  totalQuestions: totalQ,
                                  durationMinutes: duration,
                                  createdBy: 1,
                                  createdAt: selectedDate,
                                );

                                await quizzesProvider.addQuiz(newQuiz);
                                Navigator.pop(context);
                                
                                // Success dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Colors.green.shade400, Colors.teal.shade400],
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.green.shade400,
                                              size: 60,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          const Text(
                                            'Success!',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Your quiz has been created successfully!',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 28),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.green.shade600,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 40,
                                                vertical: 16,
                                              ),
                                              elevation: 0,
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text(
                                              'Great!',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
    ),
    );
  }

  void showCreateWithAiDialog(BuildContext context, QuizzesProvider quizzesProvider) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final totalQuestionsController = TextEditingController(text: '10');
    final durationController = TextEditingController(text: '15');
    final _formKey = GlobalKey<FormState>();

    String selectedCategory = 'Technology';
    String selectedDifficulty = 'Medium';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.purple.shade50]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.blue.shade400]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text('Quiz with AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: titleController,
                        label: 'Quiz Title / Topic',
                        icon: Icons.topic_rounded,
                        hint: 'e.g. Basics of Flutter',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Title / topic is required';
                          if (val.trim().length < 3) return 'Must be at least 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: descriptionController,
                        label: 'Short Description / Prompt',
                        icon: Icons.description_rounded,
                        hint: 'Briefly describe the quiz scope',
                        maxLines: 3,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Description is required';
                          if (val.trim().length < 10) return 'Description must be at least 10 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: totalQuestionsController,
                              label: 'Questions',
                              icon: Icons.format_list_numbered_rounded,
                              hint: '10',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Total questions is required';
                                final n = int.tryParse(val.trim());
                                if (n == null || n < 4) return 'Enter a valid number (minimum 4)';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: durationController,
                              label: 'Minutes',
                              icon: Icons.timer_rounded,
                              hint: '15',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Duration is required';
                                final n = int.tryParse(val.trim());
                                if (n == null || n < 5) return 'Duration must be at least 5 minutes';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.shade200)),
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          items: ['Technology','Design','Marketing','Science','AI','Web']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => selectedCategory = v!),
                          decoration: InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: Colors.purple.shade700), prefixIcon: Icon(Icons.category_rounded, color: Colors.purple.shade400), border: InputBorder.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.shade200)),
                        child: DropdownButtonFormField<String>(
                          value: selectedDifficulty,
                          items: ['Easy','Medium','Hard'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setState(() => selectedDifficulty = v!),
                          decoration: InputDecoration(labelText: 'Difficulty', labelStyle: TextStyle(color: Colors.purple.shade700), prefixIcon: Icon(Icons.bar_chart_rounded, color: Colors.purple.shade400), border: InputBorder.none),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.white),
                              label: const Text('Generate and Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: Colors.purple.shade400),
                              onPressed: () async {
                                if (!(_formKey.currentState?.validate() ?? false)) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Please fix form errors'), backgroundColor: Colors.redAccent));
                                  return;
                                }

                                final title = titleController.text.trim();
                                final desc = descriptionController.text.trim();
                                final totalQ = int.tryParse(totalQuestionsController.text.trim()) ?? 10;
                                final duration = int.tryParse(durationController.text.trim()) ?? 15;

                                // Show progress
                                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                                try {
                                  final generated = await generateQuestionsFromAi(topic: title, description: desc, totalQuestions: totalQ, difficulty: selectedDifficulty);

                                  // Insert quiz and get id
                                  final quizMap = {
                                    'title': title,
                                    'description': desc,
                                    'total_questions': totalQ,
                                    'duration_minutes': duration,
                                    'category': selectedCategory,
                                    'difficulty': selectedDifficulty,
                                    'created_by': Provider.of<AuthProvider>(context, listen: false).user?.id ?? 1,
                                    'created_at': selectedDate.toIso8601String(),
                                  };

                                  // Debug print to show the exact map we're inserting
                                  print('AI: inserting quiz map: $quizMap');
                                  final quizId = await DatabaseHelper.instance.addQuizReturnId(quizMap);
                                  if (quizId == null) throw Exception('Failed to insert quiz');

                                  // Save generated questions
                                  for (final q in generated) {
                                    final qMap = {
                                      'quiz_id': quizId,
                                      'question_text': q['question_text'] ?? '',
                                      'option_a': q['option_a'] ?? '',
                                      'option_b': q['option_b'] ?? '',
                                      'option_c': q['option_c'] ?? '',
                                      'option_d': q['option_d'] ?? '',
                                      'correct_option': q['correct_option'] ?? 'A',
                                    };
                                    await DatabaseHelper.instance.addQuestion(qMap);
                                  }

                                  Navigator.pop(context); // close progress
                                  Navigator.pop(context); // close dialog

                                  // Refresh quizzes list
                                  await quizzesProvider.loadQuizzes();

                                  // Success
                                  showDialog(context: context, builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                                      const SizedBox(height: 12),
                                      const Text('Quiz created', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      const Text('Quiz and questions generated successfully using AI.'),
                                      const SizedBox(height: 16),
                                      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Great'))
                                    ]))
                                  ));
                                } catch (e) {
                                  Navigator.pop(context); // close progress
                                  // Show error snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI generation failed: $e'), backgroundColor: Colors.redAccent));

                                  // If we have raw AI output, show it in a dialog to help debugging
                                  try {
                                    final raw = (await showDialog<String?>(
                                      context: context,
                                      builder: (context) {
                                        // Import from ai_service
                                        return AlertDialog(
                                          title: const Text('AI Response (raw)'),
                                          content: SingleChildScrollView(
                                            child: SelectableText(
                                              // Access the lastAiRawOutput variable from ai_service
                                              // We'll get it via the imported symbol
                                              lastAiRawOutput ?? 'No AI response available',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Close')),
                                          ],
                                        );
                                      },
                                    ));
                                  } catch (_) {}
                                }
                              },
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
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
}
