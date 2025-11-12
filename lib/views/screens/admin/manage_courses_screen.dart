// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constant/app_theme.dart';
import '../../../models/course_model.dart';
import '../../../models/lesson_model.dart';
import '../../../providers/courses_provider.dart';
import '../../../providers/lessons_provider.dart';
import 'add_edit_course_screen.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProv = Provider.of<CoursesProvider>(context, listen: false);
      courseProv.loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CoursesProvider, LessonsProvider>(
      builder: (context, coursesProvider, lessonsProvider, child) {
        final courses = coursesProvider.courses
            .where((c) =>
        (_selectedCategory == 'All' || c.category == _selectedCategory) &&
            (c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.description.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gérer les Cours et Leçons'),
            backgroundColor: AppTheme.errorColor,
          ),
          body: coursesProvider.isLoading
              ? const Center(
              child: CircularProgressIndicator(color: AppTheme.errorColor))
              : Column(
            children: [
              // 🔍 Recherche
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Rechercher un cours...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              // 🏷️ Filtre catégorie
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: coursesProvider.categories
                      .contains(_selectedCategory) ||
                      _selectedCategory == 'All'
                      ? _selectedCategory
                      : 'All',
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: 'All', child: Text('Toutes')),
                    ...coursesProvider.categories
                        .toSet()
                        .where((cat) =>
                    cat.isNotEmpty && cat != 'All')
                        .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat))),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value ?? 'All'),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => coursesProvider.loadCourses(),
                  color: AppTheme.errorColor,
                  child: courses.isEmpty
                      ? const Center(
                    child: Text('Aucun cours trouvé pour ce filtre.'),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return FutureBuilder<List<Lesson>>(
                        future: lessonsProvider
                            .getLessonsByCourse(course.id!),
                        builder: (context, snapshot) {
                          final lessons = snapshot.data ?? [];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            elevation: 3,
                            child: ExpansionTile(
                              leading: const Icon(Icons.menu_book,
                                  color: AppTheme.errorColor),
                              title: Text(course.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${course.category} • ${lessons.length} leçons'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      Navigator.of(context,
                                          rootNavigator: true)
                                          .push(MaterialPageRoute(
                                        builder: (ctx) =>
                                            AddEditCourseScreen(
                                                course: course),
                                      ));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: AppTheme.errorColor),
                                    onPressed: () {
                                      _confirmDeleteCourse(context,
                                          coursesProvider, course);
                                    },
                                  ),
                                ],
                              ),
                              children: [
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child:
                                    CircularProgressIndicator(
                                        color: AppTheme
                                            .errorColor),
                                  )
                                else if (lessons.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                        'Aucune leçon pour ce cours.'),
                                  )
                                else
                                  ...lessons.map((lesson) {
                                    return ListTile(
                                      title: Text(lesson.title),
                                      subtitle: Text(
                                          'Durée: ${lesson.duration ?? 0} min'),
                                      trailing: Row(
                                        mainAxisSize:
                                        MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.picture_as_pdf,
                                                color:
                                                Colors.redAccent),
                                            onPressed:
                                            lesson.pdfUrl == null
                                                ? null
                                                : () async {
                                              final url =
                                              lesson.pdfUrl!;
                                              ScaffoldMessenger.of(
                                                  context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Ouverture du PDF...'),
                                                ),
                                              );
                                              await _openPDF(
                                                  url);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.edit,
                                                color:
                                                Colors.blue),
                                            onPressed: () {
                                              _editLesson(
                                                  context,
                                                  lessonsProvider,
                                                  lesson,
                                                  course.id!);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete,
                                                color: AppTheme
                                                    .errorColor),
                                            onPressed: () async {
                                              final ok =
                                              await lessonsProvider
                                                  .deleteLesson(
                                                  lesson.id!);
                                              if (ok && mounted) {
                                                setState(() {});
                                                ScaffoldMessenger.of(
                                                    context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Leçon supprimée ✅'),
                                                    backgroundColor:
                                                    AppTheme
                                                        .successColor,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 8),
                                  child: Align(
                                    alignment:
                                    Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text(
                                          'Ajouter une leçon'),
                                      style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor:
                                        AppTheme.errorColor,
                                      ),
                                      onPressed: () {
                                        _addLesson(
                                            context,
                                            lessonsProvider,
                                            course.id!);
                                      },
                                    ),
                                  ),
                                ),
                              ],
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.errorColor,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (ctx) => const AddEditCourseScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  /// ✅ Ouvre le PDF directement dans le navigateur externe
  Future<void> _openPDF(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien PDF invalide.')),
      );
      return;
    }

    try {
      final Uri pdfUri = Uri.parse(url);

      // Ouvre le lien directement dans le navigateur par défaut (Chrome, Edge, etc.)
      if (await canLaunchUrl(pdfUri)) {
        await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d’ouvrir le PDF."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur inattendue lors de l’ouverture du PDF."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ========================
  //  SUPPRIMER UN COURS
  // ========================
  void _confirmDeleteCourse(
      BuildContext context, CoursesProvider provider, Course course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Voulez-vous vraiment supprimer le cours "${course.title}" et toutes ses leçons ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteCourse(course.id!);
              setState(() {});
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  // ========================
  //  AJOUT / MODIF LEÇON
  // ========================
  void _addLesson(
      BuildContext context, LessonsProvider provider, int courseId) {
    _showLessonDialog(context, provider, courseId);
  }

  void _editLesson(BuildContext context, LessonsProvider provider,
      Lesson lesson, int courseId) {
    _showLessonDialog(context, provider, courseId, lesson: lesson);
  }

  void _showLessonDialog(BuildContext context, LessonsProvider provider,
      int courseId, {Lesson? lesson}) {
    final titleController = TextEditingController(text: lesson?.title ?? '');
    final contentController =
    TextEditingController(text: lesson?.content ?? '');
    final durationController =
    TextEditingController(text: lesson?.duration?.toString() ?? '0');
    final pdfUrlController =
    TextEditingController(text: lesson?.pdfUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lesson == null ? 'Ajouter une leçon' : 'Modifier la leçon'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                controller: contentController,
                decoration:
                const InputDecoration(labelText: 'Contenu'),
                maxLines: 3,
              ),
              TextField(
                controller: durationController,
                decoration:
                const InputDecoration(labelText: 'Durée (min)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: pdfUrlController,
                decoration:
                const InputDecoration(labelText: 'Lien du fichier PDF'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              final newLesson = Lesson(
                id: lesson?.id,
                courseId: courseId,
                title: titleController.text.trim(),
                content: contentController.text.trim(),
                duration: int.tryParse(durationController.text) ?? 0,
                pdfUrl: pdfUrlController.text.trim().isEmpty
                    ? null
                    : pdfUrlController.text.trim(),
                createdAt: DateTime.now().toIso8601String(),
              );

              final success = lesson == null
                  ? await provider.addLesson(newLesson)
                  : await provider.updateLesson(newLesson);

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? lesson == null
                      ? 'Leçon ajoutée ✅'
                      : 'Leçon mise à jour ✅'
                      : 'Erreur lors de l’enregistrement'),
                ));
                setState(() {});
              }
            },
            child: Text(lesson == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}
