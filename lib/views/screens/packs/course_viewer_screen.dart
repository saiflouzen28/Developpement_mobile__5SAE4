import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import '../../../models/course.dart';
import 'dart:typed_data';
import 'dart:io';

class CourseViewerScreen extends StatefulWidget {
  final int packId;
  final List<Course> courses;

  const CourseViewerScreen({super.key, required this.packId, required this.courses});

  @override
  State<CourseViewerScreen> createState() => _CourseViewerScreenState();
}

class _CourseViewerScreenState extends State<CourseViewerScreen> {
  Map<int, bool> loadingMap = {};

  Future<void> _openPdf(Course course, int index) async {
    setState(() => loadingMap[index] = true);

    try {
      Uint8List pdfData;

      if (course.filePath.startsWith("http")) {
        final dio = Dio();
        final response = await dio.get<List<int>>(
          course.filePath,
          options: Options(responseType: ResponseType.bytes),
        );
        pdfData = Uint8List.fromList(response.data!);
      } else {
        final file = File(course.filePath);
        if (!await file.exists()) throw Exception('Fichier non trouvé');
        pdfData = await file.readAsBytes();
      }

      if (pdfData.isEmpty) throw Exception('Le fichier PDF est vide');

      final header = String.fromCharCodes(pdfData.take(4));
      if (header != '%PDF') throw Exception('Le fichier n’est pas un PDF valide');

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(pdfBytes: pdfData, title: course.title),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ouverture PDF: $e')),
      );
    } finally {
      setState(() => loadingMap[index] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Cours du pack',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.courses.length,
        itemBuilder: (context, i) {
          final c = widget.courses[i];
          final isLoading = loadingMap[i] ?? false;

          // Palette de dégradés différents pour chaque cours
          final colors = [
            [Colors.deepPurple.shade400, Colors.deepPurple.shade200],
            [Colors.orange.shade400, Colors.orange.shade200],
            [Colors.green.shade400, Colors.green.shade200],
            [Colors.blue.shade400, Colors.blue.shade200],
            [Colors.red.shade400, Colors.red.shade200],
          ];
          final gradient = colors[i % colors.length];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (c.description != null && c.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        c.description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _openPdf(c, i),
                      icon: isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: Text(
                        isLoading ? 'Chargement...' : 'Ouvrir le cours',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfBytes, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: SfPdfViewer.memory(pdfBytes),
    );
  }
}
