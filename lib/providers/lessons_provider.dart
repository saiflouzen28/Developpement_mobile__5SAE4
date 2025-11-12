import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/lesson_model.dart';

class LessonsProvider with ChangeNotifier {
  final _db = DatabaseHelper.instance;

  // ============================
  //        ÉTAT INTERNE
  // ============================
  List<Lesson> _lessons = [];
  bool _isLoading = false;
  String? _error;

  // ============================
  //        GETTERS PUBLICS
  // ============================
  List<Lesson> get lessons => _lessons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================
  //       CHARGEMENT GLOBAL
  // ============================
  Future<void> loadLessons() async {
    _setLoading(true);
    _setError(null);

    try {
      final rows = await _db.getAllLessons();
      _lessons = rows.map((m) => Lesson.fromMap(m)).toList();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des leçons: $e');
      _setLoading(false);
    }
  }

  Future<void> refresh() => loadLessons();

  // ============================
  //          CRUD ADMIN
  // ============================

  /// Ajouter une leçon
  Future<bool> addLesson(Lesson lesson) async {
    try {
      await _db.insertLesson(lesson.toMap());
      await loadLessons();
      return true;
    } catch (e) {
      _setError('Erreur ajout leçon: $e');
      return false;
    }
  }

  /// Modifier une leçon
  Future<bool> updateLesson(Lesson lesson) async {
    if (lesson.id == null) return false;
    try {
      await _db.updateLesson(lesson.id!, lesson.toMap());
      await loadLessons();
      return true;
    } catch (e) {
      _setError('Erreur mise à jour leçon: $e');
      return false;
    }
  }

  /// Supprimer une leçon
  Future<bool> deleteLesson(int id) async {
    try {
      await _db.deleteLesson(id);
      _lessons.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur suppression leçon: $e');
      return false;
    }
  }

  // ============================
  //      REQUÊTES SPÉCIFIQUES
  // ============================

  /// Obtenir toutes les leçons d’un cours
  Future<List<Lesson>> getLessonsByCourse(int courseId) async {
    try {
      final rows = await _db.getLessonsByCourse(courseId);
      return rows.map((m) => Lesson.fromMap(m)).toList();
    } catch (e) {
      _setError('Erreur chargement leçons du cours: $e');
      return [];
    }
  }

  /// Obtenir une seule leçon par son ID
  Future<Lesson?> getLessonById(int id) async {
    try {
      final data = await _db.getLessonById(id);
      return data == null ? null : Lesson.fromMap(data);
    } catch (e) {
      _setError('Erreur récupération leçon: $e');
      return null;
    }
  }

  // ============================
  //         UTILITAIRES
  // ============================
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }
}
