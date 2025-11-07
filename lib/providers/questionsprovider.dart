import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/question_model.dart';

class QuestionsProvider with ChangeNotifier {
  List<Question> _questions = [];
  bool _isLoading = false;
  String? _error;

  // ====== Getters ======
  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ====== Load all questions for a quiz ======
  Future<void> loadQuestions(int quizId) async {
    _setLoading(true);
    _setError(null);

    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'questions',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
        orderBy: 'id ASC',
      );
      _questions = result.map((e) => Question.fromMap(e)).toList();
      _setLoading(false);

      // ✅ Notify UI to rebuild
      notifyListeners();
    } catch (e) {
      _setError('Failed to load questions: ${e.toString()}');
      _setLoading(false);
    }
  }


  // ====== Add a new question ======
  Future<void> addQuestion(Question question) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('questions', question.toMap());
      await loadQuestions(question.quizId); // Refresh list
    } catch (e) {
      _setError('Failed to add question: ${e.toString()}');
    }
  }

  // ====== Update a question ======
  Future<void> updateQuestion(Question question) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'questions',
        question.toMap(),
        where: 'id = ?',
        whereArgs: [question.id],
      );
      await loadQuestions(question.quizId); // Refresh list
    } catch (e) {
      _setError('Failed to update question: ${e.toString()}');
    }
  }

  // ====== Delete a question ======
  Future<void> deleteQuestion(int id, int quizId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('questions', where: 'id = ?', whereArgs: [id]);
      await loadQuestions(quizId); // Refresh list
    } catch (e) {
      _setError('Failed to delete question: ${e.toString()}');
    }
  }

  // ====== Helpers ======
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

  void clearQuestions() {
    _questions = [];
    notifyListeners();
  }
}
