// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../services/ai_service.dart';
import '../../../services/ai_translate_service.dart';
import '../../../providers/courses_provider.dart';
import '../../../models/course_model.dart';
import '../../../models/lesson_model.dart';
import '../../../core/constant/app_theme.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({super.key});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  Course? _course;
  List<Lesson> _lessons = [];
  bool _loading = true;

  // ⭐ Variables pour l’évaluation
  double _userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _reviews = [];

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  String _currentSpeakingText = '';
  final Set<int> _expandedLessons = {};

  @override
  void initState() {
    super.initState();
    _initTTS();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _currentSpeakingText = '';
      });
    });
  }

  Future<void> _saveReviews() async {
    if (_course == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = _reviews.map((r) => jsonEncode(r)).toList();
    await prefs.setStringList('reviews_${_course!.id}', data);
  }

  Future<void> _loadReviews() async {
    if (_course == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('reviews_${_course!.id}');
    if (data != null) {
      setState(() {
        _reviews
          ..clear()
          ..addAll(
            data
                .map((e) => jsonDecode(e) as Map<String, dynamic>)
                .toList(),
          );
      });
    }
  }

  Future<void> _load() async {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final provider = context.read<CoursesProvider>();
    final course = await provider.getCourse(id);
    final lessons = await provider.getLessons(id);

    if (!mounted) return;
    setState(() {
      _course = course;
      _lessons = lessons;
      _loading = false;
    });

    await _loadReviews(); // 🔹 Charger les avis sauvegardés
  }

  // ✅ Fonction Wikipédia simple
  Future<void> _openWikipediaSearch(String query) async {
    final Uri url = Uri.parse(
        "https://fr.wikipedia.org/wiki/${Uri.encodeComponent(query)}");
    if (!await canLaunchUrl(url)) {
      _showSnackBar("Impossible d’ouvrir Wikipédia.", Colors.redAccent);
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openPDF(Lesson lesson) async {
    if (lesson.pdfUrl == null || lesson.pdfUrl!.isEmpty) {
      _showSnackBar("Lien PDF invalide.", Colors.orangeAccent);
      return;
    }
    try {
      final Uri pdfUri = Uri.parse(lesson.pdfUrl!);
      if (!await canLaunchUrl(pdfUri)) {
        _showSnackBar("Impossible d’ouvrir le lien PDF.", Colors.redAccent);
        return;
      }
      await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnackBar("Erreur lors de l’ouverture du PDF: $e", Colors.redAccent);
    }
  }

  Future<void> _toggleSpeak(String text) async {
    if (_isSpeaking && _currentSpeakingText == text) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
        _currentSpeakingText = '';
      });
      return;
    }
    await _tts.stop();
    setState(() {
      _isSpeaking = true;
      _currentSpeakingText = text;
    });
    await _tts.speak(text);
  }

  /// ✅ Traduction (API MyMemory)
  Future<void> _translateLesson(Lesson l) async {
    String textToTranslate = "";
    if (l.pdfUrl != null && l.pdfUrl!.isNotEmpty) {
      textToTranslate = await AIService.extractTextFromPDF(l.pdfUrl!);
    } else {
      textToTranslate = l.content;
    }

    String? targetLang = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("🌍 Choisir la langue de traduction"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.blue),
              title: const Text("Français"),
              onTap: () => Navigator.pop(context, "fr"),
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text("Anglais"),
              onTap: () => Navigator.pop(context, "en"),
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.green),
              title: const Text("Arabe"),
              onTap: () => Navigator.pop(context, "ar"),
            ),
          ],
        ),
      ),
    );

    if (targetLang == null) return;

    _showSnackBar("🌐 Traduction en cours (${targetLang.toUpperCase()})...", Colors.deepPurple);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AITRanslateDialog(),
    );

    final translation = await AITranslateService.translate(
      text: textToTranslate,
      targetLang: targetLang,
    );

    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("🌍 Traduction (${targetLang.toUpperCase()})"),
        content: SingleChildScrollView(
          child: Text(translation, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: translation));
              Navigator.pop(context);
              _showSnackBar("Traduction copiée !", Colors.green);
            },
            icon: const Icon(Icons.copy, color: Colors.black54),
            label: const Text("Copier"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.info_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoursesProvider>();
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }
    if (_course == null) {
      return const Scaffold(body: Center(child: Text('Cours introuvable')));
    }

    final c = _course!;
    final banner = c.imageUrl;
    final progress = provider.progressForCourse(c.id!);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 260,
              backgroundColor: AppTheme.primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 12),
                title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (banner != null)
                      CachedNetworkImage(
                        imageUrl: banner,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => _bannerFallback(),
                      )
                    else
                      _bannerFallback(),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// ===================== CONTENU =====================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progression du cours',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 6),
                    Text('${progress.toStringAsFixed(1)}% complété',
                        style: const TextStyle(fontWeight: FontWeight.w600)),

                    const SizedBox(height: 24),
                    Text('Leçons du cours',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),

                    const SizedBox(height: 8),
                    if (_lessons.isEmpty)
                      _emptyLessonsCard(context)
                    else
                      ..._lessons.map((l) {
                        final done = provider.isLessonCompleted(c.id!, l.id ?? 0);
                        final isSpeakingThis =
                            _isSpeaking && _currentSpeakingText == l.content;

                        return FadeInUp(
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            color: done ? Colors.green.withOpacity(0.05) : Colors.white,
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        done
                                            ? Icons.check_circle
                                            : Icons.menu_book_outlined,
                                        color:
                                        done ? Colors.green : AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            HapticFeedback.lightImpact();
                                            await _openWikipediaSearch(l.title);
                                          },
                                          child: Text(
                                            l.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(l.content,
                                      maxLines: 3, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _ActionIcon(
                                        icon: Icons.auto_awesome,
                                        color: AppTheme.primaryColor,
                                        tooltip: "Résumer",
                                        onTap: () async {
                                          _showSnackBar(
                                              "⏳ Résumé en cours...", Colors.blueGrey);
                                          String summary = l.pdfUrl != null &&
                                              l.pdfUrl!.isNotEmpty
                                              ? await AIService.summarizePDF(l.pdfUrl!)
                                              : await AIService.summarizeText(l.content);
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("🧠 Résumé"),
                                              content: SingleChildScrollView(
                                                  child: Text(summary)),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text("Fermer"),
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      _ActionIcon(
                                        icon: Icons.picture_as_pdf,
                                        color: Colors.redAccent,
                                        tooltip: "Ouvrir le PDF",
                                        onTap: () async => await _openPDF(l),
                                      ),

                                      _ActionIcon(
                                        icon: Icons.language_rounded,
                                        color: Colors.deepPurple,
                                        tooltip: "Traduire",
                                        onTap: () => _translateLesson(l),
                                      ),
                                      _ActionIcon(
                                        icon: isSpeakingThis
                                            ? Icons.pause_circle_filled
                                            : Icons.volume_up_rounded,
                                        color:
                                        isSpeakingThis ? Colors.orange : Colors.teal,
                                        tooltip: "Lire à voix haute",
                                        onTap: () async =>
                                        await _toggleSpeak(l.content),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 40),
                    const Divider(thickness: 1),
                    const Text(
                      "⭐ Évaluer ce cours",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() => _userRating = index + 1.0);
                          },
                          icon: Icon(
                            index < _userRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 30,
                          ),
                        );
                      }),
                    ),
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Ajoutez un commentaire (facultatif)",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_userRating == 0) {
                          _showSnackBar(
                              "Veuillez donner une note.", Colors.redAccent);
                          return;
                        }
                        setState(() {
                          _reviews.add({
                            "note": _userRating,
                            "comment": _commentController.text.trim(),
                            "date": DateTime.now().toString(),
                          });
                          _userRating = 0;
                          _commentController.clear();
                        });
                        _saveReviews(); // ✅ Sauvegarde locale
                        _showSnackBar("Merci pour votre avis !", Colors.green);
                      },
                      icon: const Icon(Icons.send),
                      label: const Text("Envoyer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_reviews.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("🗨️ Avis récents :",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          ..._reviews.map(
                                (r) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(
                                    "⭐ ${r["note"]} / 5  -  ${r["date"].toString().split('.')[0]}"),
                                subtitle: Text(r["comment"].isEmpty
                                    ? "Aucun commentaire"
                                    : r["comment"]),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyLessonsCard(BuildContext context) => Card(
    elevation: 0,
    color: Colors.orange.withOpacity(0.06),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Colors.orangeAccent),
    ),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Aucune leçon enregistrée pour ce cours.'),
    ),
  );

  Widget _bannerFallback() => Container(
    color: AppTheme.primaryColor.withOpacity(0.12),
    child: const Center(
      child: Icon(Icons.menu_book, size: 72, color: Colors.white70),
    ),
  );
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Tooltip(
    message: tooltip,
    child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(50),
    child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
    color: color.withOpacity(0.1),
    shape: BoxShape.circle,
    boxShadow: [
    BoxShadow(
    color: color.withOpacity(0.3),
    blurRadius: 8,
    spreadRadius: 1,
    offset: const Offset(0, 3),
    ),
    ],
    ),
      child: Icon(icon, color: color, size: 28),
    ),
    ),
    ),
    );
  }
}

class _AITRanslateDialog extends StatelessWidget {
  const _AITRanslateDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.75),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: Colors.deepPurpleAccent,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "L’IA traduit le contenu...",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "Analyse du texte et génération en cours...",
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
