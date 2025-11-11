import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../models/course.dart';
import '../../../providers/course_repository.dart';
import 'add_course_form.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({Key? key}) : super(key: key);

  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  final CourseRepository _courseRepo = CourseRepository();
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final data = await _courseRepo.getAllCourses();
    setState(() {
      _courses = data;
      _filteredCourses = data;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCourses = _courses.where((course) {
        return course.title.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddCourseForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        child: AddCourseForm(
          onCourseAdded: () {
            Navigator.pop(context);
            _loadCourses();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cours ajouté avec succès')),
            );
          },
        ),
      ),
    );
  }

  void _deleteCourse(int id) async {
    await _courseRepo.deleteCourse(id);
    _loadCourses();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cours supprimé')),
    );
  }

  void _openPdf(String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(filePath: filePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseForm,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, size: 30),
        tooltip: 'Ajouter un cours',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : Column(
        children: [
          // ====== BARRE DE RECHERCHE ======
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un cours...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // ====== LISTE DES COURS ======
          Expanded(
            child: _filteredCourses.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.menu_book, size: 80, color: Colors.deepPurple),
                  SizedBox(height: 20),
                  Text(
                    'Aucun cours trouvé.',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _filteredCourses.length,
              itemBuilder: (context, index) {
                final course = _filteredCourses[index];
                return GestureDetector(
                  onTap: () => _openPdf(course.filePath),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: const Icon(Icons.picture_as_pdf,
                          color: Colors.white, size: 40),
                      title: Text(
                        course.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                      ),
                      subtitle: course.description != null
                          ? Text(
                        course.description!,
                        style: const TextStyle(color: Colors.white70),
                      )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.white),
                            onPressed: () => _openPdf(course.filePath),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteCourse(course.id!),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- PDF Viewer Screen ----------------
class PdfViewerScreen extends StatelessWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Lecture PDF'),
        backgroundColor: Colors.deepPurple,
      ),
      body: filePath.startsWith('assets/')
          ? SfPdfViewer.asset(filePath)
          : SfPdfViewer.file(File(filePath)),
    );
  }
}
