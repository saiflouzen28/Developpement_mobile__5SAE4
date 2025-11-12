import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/app_theme.dart';
import '../../../models/course_model.dart';
import '../../../providers/courses_provider.dart';
import '../../../services/local_ai_course_generator.dart';

// ========================================================
// 🧩 ÉCRAN PRINCIPAL : AJOUT / MODIFICATION DE COURS
// ========================================================
class AddEditCourseScreen extends StatefulWidget {
  final Course? course;

  const AddEditCourseScreen({super.key, this.course});

  bool get isEditing => course != null;

  @override
  State<AddEditCourseScreen> createState() => _AddEditCourseScreenState();
}

class _AddEditCourseScreenState extends State<AddEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _lessonsCountController;

  String _selectedCategory = 'Développement';
  bool _isSaving = false;
  bool _isGenerating = false;

  final List<String> _categories = [
    'Développement',
    'Design',
    'Marketing',
    'Intelligence Artificielle',
    'Business',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.course?.description ?? '');
    _imageUrlController =
        TextEditingController(text: widget.course?.imageUrl ?? '');
    _lessonsCountController = TextEditingController(
        text: widget.course?.lessonsCount.toString() ?? '0');
    _selectedCategory = widget.course?.category ?? 'Développement';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _lessonsCountController.dispose();
    super.dispose();
  }

  // ✅ Sauvegarde du cours
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = Provider.of<CoursesProvider>(context, listen: false);

    final newCourse = Course(
      id: widget.course?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      category: _selectedCategory,
      lessonsCount: int.tryParse(_lessonsCountController.text) ?? 0,
      createdAt: DateTime.now().toIso8601String(),
    );

    bool success = widget.isEditing
        ? await provider.updateCourse(newCourse)
        : await provider.addCourse(newCourse);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Cours enregistré avec succès ✅'
            : 'Échec lors de l\'enregistrement'),
        backgroundColor:
        success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );

    if (success) Navigator.of(context).pop();
    setState(() => _isSaving = false);
  }

  // 🤖 Génération du plan IA
  Future<void> _generatePlan() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Entrez un titre avant de générer.')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    // 🔮 Affiche une animation IA immersive
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AILoadingDialog(),
    );

    await Future.delayed(const Duration(seconds: 3)); // simulation réflexion IA
    final plan =
    await LocalAICourseGenerator.generateCoursePlan(_titleController.text);

    if (!mounted) return;
    Navigator.pop(context); // ferme le dialog
    setState(() => _isGenerating = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AutoCoursePlanScreen(
          courseTitle: _titleController.text.trim(),
          plan: plan,
        ),
      ),
    );
  }

  // 🧱 UI principale
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.isEditing ? 'Modifier le cours' : 'Ajouter un cours'),
        backgroundColor: AppTheme.errorColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _submitForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration:
                  const InputDecoration(labelText: 'Titre du cours'),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Entrez un titre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration:
                  const InputDecoration(labelText: 'Description du cours'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((cat) =>
                      DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lessonsCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Nombre de leçons (facultatif)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                      labelText: 'Image (URL ou lien locale)'),
                ),
                const SizedBox(height: 30),

                // 🧠 Bouton IA
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating
                      ? "L’IA réfléchit..."
                      : "🧠 Générer un plan intelligent"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isGenerating ? null : _generatePlan,
                ),
                const SizedBox(height: 16),

                // 💾 Sauvegarde
                ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.check),
                  label: Text(widget.isEditing
                      ? 'Mettre à jour le cours'
                      : 'Ajouter le cours'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================================
// 🌟 DIALOGUE ANIMÉ DE RÉFLEXION IA
// ========================================================
class _AILoadingDialog extends StatelessWidget {
  const _AILoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.75),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "L’IA réfléchit à un plan unique...",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Analyse du sujet, création des chapitres,\norganisation du plan...",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================================
// 🧠 PAGE MODERNE : PLAN GÉNÉRÉ AUTOMATIQUEMENT
// ========================================================
class AutoCoursePlanScreen extends StatelessWidget {
  final String courseTitle;
  final List<Map<String, String>> plan;

  const AutoCoursePlanScreen({
    super.key,
    required this.courseTitle,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.errorColor,
        elevation: 0,
        title: Text(
          "🧩 Plan du cours – $courseTitle",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: plan.isEmpty
          ? const Center(
        child: Text(
          "Aucun plan généré.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plan.length,
        itemBuilder: (context, i) {
          final item = plan[i];
          final progress = ((i + 1) / plan.length);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade50,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                            Colors.deepPurpleAccent.shade100,
                            child: Text(
                              "${i + 1}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item["title"] ?? "",
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item["description"] ?? "",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.deepPurple,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Retour"),
        ),
      ),
    );
  }
}
