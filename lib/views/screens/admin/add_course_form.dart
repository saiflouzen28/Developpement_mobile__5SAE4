import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/course.dart';
import '../../../providers/course_repository.dart';

class AddCourseForm extends StatefulWidget {
  final VoidCallback onCourseAdded;

  const AddCourseForm({Key? key, required this.onCourseAdded}) : super(key: key);

  @override
  State<AddCourseForm> createState() => _AddCourseFormState();
}

class _AddCourseFormState extends State<AddCourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _pdfPath;
  final CourseRepository _courseRepo = CourseRepository();

  Future<void> _pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfPath = result.files.single.path!;
      });
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate() || _pdfPath == null) return;

    final course = Course(
      title: _titleCtrl.text,
      description: _descCtrl.text,
      filePath: _pdfPath!,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _courseRepo.insertCourse(course);
    widget.onCourseAdded();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              "Ajouter un nouveau cours",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: "Titre du cours"),
              validator: (v) => v == null || v.isEmpty ? "Titre requis" : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _pdfPath == null
                        ? "Aucun fichier sélectionné"
                        : File(_pdfPath!).path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickPdfFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text("Choisir PDF"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveCourse,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
