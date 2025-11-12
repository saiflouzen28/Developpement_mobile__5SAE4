import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/review_model.dart';

class CoursesProvider with ChangeNotifier {
  final _db = DatabaseHelper.instance;

  // --- Données principales ---
  List<Course> _courses = [];
  List<Course> _filtered = [];
  List<String> _categories = ['All'];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  // --- Favoris ---
  final Set<int> _favoriteIds = {};
  bool _showOnlyFavorites = false;

  // --- Ratings / Avis ---
  final Map<int, double> _avgRatings = {}; // courseId -> moyenne
  final Map<int, int> _ratingCounts = {}; // courseId -> nb avis
  final Map<int, List<Review>> _courseReviewsCache = {};

  // --- Nouvel ajout : cache des PDF par leçon ---
  final Map<int, String> _pdfLinksCache = {}; // lessonId -> pdfUrl

  // --- Nouvel ajout : progression ---
  final Map<int, Set<int>> _completedLessons = {}; // courseId -> set de lessonIds
  final Map<int, double> _progressByCourse = {}; // courseId -> pourcentage

  // --- Getters ---
  List<Course> get courses => _filtered;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Set<int> get favoriteIds => _favoriteIds;
  bool get showOnlyFavorites => _showOnlyFavorites;

  double avgFor(int courseId) => _avgRatings[courseId] ?? 0;
  int countFor(int courseId) => _ratingCounts[courseId] ?? 0;
  List<Review> reviewsFor(int courseId) => _courseReviewsCache[courseId] ?? [];

  double progressForCourse(int courseId) => _progressByCourse[courseId] ?? 0;

  bool isLessonCompleted(int courseId, int lessonId) =>
      _completedLessons[courseId]?.contains(lessonId) ?? false;

  // ============================================================
  //                      CHARGEMENT INITIAL
  // ============================================================
  Future<void> loadCourses() async {
    _setLoading(true);
    _setError(null);
    try {
      final rows = await _db.getAllCourses();
      _courses = rows.map((m) => Course.fromMap(m)).toList();
      _filtered = List.from(_courses);

      final cats = await _db.getCourseCategories();
      _categories = ['All', ...cats];

      await _loadFavorites();
      await _loadAllRatingsFromPrefs();
      await _loadAllPdfLinks();
      await _loadProgress();

      _applyFilters();
    } catch (e) {
      _setError('Erreur chargement cours: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => loadCourses();

  // ============================================================
  //                        CRUD ADMIN
  // ============================================================
  Future<bool> addCourse(Course course) async {
    try {
      await _db.insertCourse(course.toMap());
      await loadCourses();
      return true;
    } catch (e) {
      _setError('Erreur ajout cours: $e');
      return false;
    }
  }

  Future<bool> updateCourse(Course course) async {
    if (course.id == null) return false;
    try {
      await _db.updateCourse(course.id!, course.toMap());
      await loadCourses();
      return true;
    } catch (e) {
      _setError('Erreur mise à jour cours: $e');
      return false;
    }
  }

  Future<bool> deleteCourse(int id) async {
    try {
      await _db.deleteCourse(id);
      _courses.removeWhere((c) => c.id == id);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur suppression cours: $e');
      return false;
    }
  }

  // ============================================================
  //                        FILTRAGE
  // ============================================================
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    _showOnlyFavorites = false;
    _filtered = List.from(_courses);
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _courses.where((c) {
      final catOk = _selectedCategory == 'All' || c.category == _selectedCategory;
      final q = _searchQuery;
      final searchOk = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q);

      final favOk = !_showOnlyFavorites || _favoriteIds.contains(c.id);
      return catOk && searchOk && favOk;
    }).toList();
  }

  // ============================================================
  //                        DETAILS
  // ============================================================
  Future<Course?> getCourse(int id) async {
    try {
      final data = await _db.getCourseById(id);
      return data == null ? null : Course.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<Lesson>> getLessons(int courseId) async {
    try {
      final rows = await _db.getLessonsByCourse(courseId);
      final lessons = rows.map((m) => Lesson.fromMap(m)).toList();

      for (final lesson in lessons) {
        if (lesson.id != null && lesson.pdfUrl != null) {
          _pdfLinksCache[lesson.id!] = lesson.pdfUrl!;
        }
      }
      _updateProgress(courseId, lessons.length);
      return lessons;
    } catch (e) {
      _setError('Erreur chargement leçons: $e');
      return [];
    }
  }

  // ============================================================
  //                FONCTIONNALITÉ AVANCÉE : PROGRESSION
  // ============================================================
  Future<void> markLessonCompleted(int courseId, int lessonId, int totalLessons) async {
    _completedLessons.putIfAbsent(courseId, () => {});
    _completedLessons[courseId]!.add(lessonId);
    _updateProgress(courseId, totalLessons);
    await _saveProgress();
    notifyListeners();
  }

  void _updateProgress(int courseId, int totalLessons) {
    final completed = _completedLessons[courseId]?.length ?? 0;
    final percent = totalLessons == 0 ? 0 : completed / totalLessons;
    _progressByCourse[courseId] = double.parse((percent * 100).toStringAsFixed(1));
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _completedLessons.map((k, v) => MapEntry(k.toString(), v.toList()));
    await prefs.setString('completed_lessons', jsonEncode(data));
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('completed_lessons');
    if (str == null) return;
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    _completedLessons.clear();
    decoded.forEach((k, v) {
      _completedLessons[int.parse(k)] = Set<int>.from(v);
    });
  }

  // ============================================================
  //                  NOUVELLE FONCTIONNALITÉ PDF
  // ============================================================
  Future<void> _loadAllPdfLinks() async {
    try {
      final rows = await _db.getAllLessons();
      for (final m in rows) {
        final lesson = Lesson.fromMap(m);
        if (lesson.id != null && lesson.pdfUrl != null) {
          _pdfLinksCache[lesson.id!] = lesson.pdfUrl!;
        }
      }
    } catch (e) {
      debugPrint("Erreur chargement liens PDF: $e");
    }
  }

  String? getPdfForLesson(int lessonId) => _pdfLinksCache[lessonId];

  // ============================================================
  // FAVORIS, AVIS, UTILITAIRES (inchangés)
  // ============================================================
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorite_course_ids') ?? [];
    _favoriteIds..clear()..addAll(ids.map(int.parse));
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorite_course_ids',
      _favoriteIds.map((e) => e.toString()).toList(),
    );
  }

  Future<void> toggleFavorite(int courseId) async {
    if (_favoriteIds.contains(courseId)) {
      _favoriteIds.remove(courseId);
    } else {
      _favoriteIds.add(courseId);
    }
    await _saveFavorites();
    _applyFilters();
    notifyListeners();
  }

  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    _applyFilters();
    notifyListeners();
  }

  // ============================================================
  // NOTES & AVIS
  // ============================================================
  String _keyForCourse(int courseId) => 'reviews_course_$courseId';

  Future<List<Review>> _readReviews(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyForCourse(courseId));
    if (str == null) return [];
    return Review.decodeList(str);
  }

  Future<void> _writeReviews(int courseId, List<Review> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyForCourse(courseId), Review.encodeList(items));
  }

  Future<void> _loadAllRatingsFromPrefs() async {
    _avgRatings.clear();
    _ratingCounts.clear();
    _courseReviewsCache.clear();
    for (final c in _courses) {
      final id = c.id;
      if (id == null) continue;
      final list = await _readReviews(id);
      _courseReviewsCache[id] = list;
      if (list.isEmpty) {
        _avgRatings[id] = 0;
        _ratingCounts[id] = 0;
      } else {
        final sum = list.fold<int>(0, (acc, r) => acc + r.rating);
        _avgRatings[id] = double.parse((sum / list.length).toStringAsFixed(2));
        _ratingCounts[id] = list.length;
      }
    }
    notifyListeners();
  }

  Future<void> loadReviews(int courseId) async {
    final list = await _readReviews(courseId);
    _courseReviewsCache[courseId] = list;
    _recompute(courseId, list);
    notifyListeners();
  }

  Future<void> addReview({
    required int courseId,
    required int rating,
    String? comment,
  }) async {
    final current = await _readReviews(courseId);
    current.insert(0, Review(rating: rating, comment: comment));
    await _writeReviews(courseId, current);
    _courseReviewsCache[courseId] = current;
    _recompute(courseId, current);
    notifyListeners();
  }

  void _recompute(int courseId, List<Review> list) {
    if (list.isEmpty) {
      _avgRatings[courseId] = 0;
      _ratingCounts[courseId] = 0;
      return;
    }
    final sum = list.fold<int>(0, (acc, r) => acc + r.rating);
    final avg = sum / list.length;
    _avgRatings[courseId] = double.parse(avg.toStringAsFixed(2));
    _ratingCounts[courseId] = list.length;
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }
}
