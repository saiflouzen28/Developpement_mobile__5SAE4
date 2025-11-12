import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/quizze_model.dart';

class QuizzesProvider with ChangeNotifier {
  List<Quiz> _quizzes = [];
  List<Quiz> _filteredQuizzes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // ====== Getters ======
  List<Quiz> get quizzes => _filteredQuizzes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // ====== Load all quizzes ======
  Future<void> loadQuizzes() async {
    _setLoading(true);
    _setError(null);

    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('quizzes');
      _quizzes = result.map((e) => Quiz.fromMap(e)).toList();
      _filteredQuizzes = List.from(_quizzes);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load quizzes: ${e.toString()}');
      _setLoading(false);
    }
  }

  // ====== Add new quiz ======
  Future<void> addQuiz(Quiz quiz) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('quizzes', quiz.toMap());
      await loadQuizzes(); // Refresh list
    } catch (e) {
      _setError('Failed to add quiz: ${e.toString()}');
    }
  }


  // ====== Update quiz ======
  Future<void> updateQuiz(Quiz quiz) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'quizzes',
        quiz.toMap(),
        where: 'id = ?',
        whereArgs: [quiz.id],
      );
      await loadQuizzes();
    } catch (e) {
      _setError('Failed to update quiz: ${e.toString()}');
    }
  }

  // ====== Delete quiz ======
  Future<void> deleteQuiz(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('quizzes', where: 'id = ?', whereArgs: [id]);
      await loadQuizzes();
    } catch (e) {
      _setError('Failed to delete quiz: ${e.toString()}');
    }
  }

  // ====== Search filter ======
  void searchQuizzes(String query) {
    _searchQuery = query.toLowerCase();
    _filteredQuizzes = _quizzes.where((quiz) {
      final title = quiz.title.toLowerCase() ?? '';
      final description = quiz.description?.toLowerCase() ?? '';
      return title.contains(_searchQuery) || description.contains(_searchQuery);
    }).toList();
    notifyListeners();
  }


  // ====== Helpers ======
  void clearSearch() {
    _searchQuery = '';
    _filteredQuizzes = List.from(_quizzes);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
