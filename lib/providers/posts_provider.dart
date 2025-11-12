import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/postulation_model.dart';

class PostsProvider with ChangeNotifier {
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Post> get posts => _filteredPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Load all posts from DB
  Future<void> loadPosts() async {
    _setLoading(true);
    _setError(null);
    try {
      final postsData = await DatabaseHelper.instance.getAllPosts(); // List<Map>
      _posts = postsData.map((e) => Post.fromMap(e)).toList(); // Correct
      _filteredPosts = List.from(_posts);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load posts: ${e.toString()}');
      _setLoading(false);
    }
  }


  Future<void> refreshPosts() async {
    await loadPosts();
  }

  // Search posts by title, content, or tags
  void searchPosts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredPosts = _posts.where((post) {
      bool searchMatch = _searchQuery.isEmpty ||
          post.title.toLowerCase().contains(_searchQuery) ||
          post.description.toLowerCase().contains(_searchQuery) ||
          post.tags.toLowerCase().contains(_searchQuery);
      return searchMatch;
    }).toList();
  }


  void clearFilters() {
    _searchQuery = '';
    _filteredPosts = List.from(_posts);
    notifyListeners();
  }

  // CRUD operations
  Future<bool> addPost(Post post) async {
    final success = await DatabaseHelper.instance.addPost(post.toMap());
    if (success) {
      await loadPosts(); // reload after adding
      return true;
    }
    return false;
  }

  Future<bool> updatePost(Post post) async {
    try {
      final success = await DatabaseHelper.instance.updatePost(post.toMap());
      if (success) {
        await loadPosts();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update post: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deletePost(int postId) async {
    try {
      final success = await DatabaseHelper.instance.deletePost(postId);
      if (success) {
        await loadPosts();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete post: ${e.toString()}');
      return false;
    }
  }

  // Optional: fetch posts by a specific user
  Future<List<Post>> getUserPosts(int userId) async {
    try {
      final postsData = await DatabaseHelper.instance.getUserPosts(userId);
      return postsData.map((e) => Post.fromMap(e)).toList();
    } catch (e) {
      _setError('Failed to load user posts: ${e.toString()}');
      return [];
    }
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

  // Liste des posts favoris (stocke les post.id)
  List<int> _favoritePosts = [];
  List<int> get favoritePosts => _favoritePosts;

  bool isFavorite(int postId) => _favoritePosts.contains(postId);
  void addFavorite(int postId) {
    if (!_favoritePosts.contains(postId)) {
      _favoritePosts.add(postId);
      notifyListeners();
    }
  }
  void removeFavorite(int postId) {
    _favoritePosts.remove(postId);
    notifyListeners();
  }





}
