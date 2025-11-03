import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/event_model.dart';

class EventsProvider with ChangeNotifier {
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<Event> get events => _filteredEvents;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> loadEvents() async {
    _setLoading(true);
    _setError(null);

    try {
      final eventsData = await DatabaseHelper.instance.getAllEvents();
      _events = eventsData.map((e) => Event.fromMap(e)).toList();
      _applyFilters(); // Use applyFilters to ensure consistency

      // Load categories
      _categories = ['All', ...await DatabaseHelper.instance.getEventCategories()];

    } catch (e) {
      _setError('Failed to load events: ${e.toString()}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // --- NEW METHODS FOR ADMIN CRUD ---
  Future<bool> addEvent(Event event) async {
    try {
      final newId = await DatabaseHelper.instance.addEvent(event.toMapForDb());
      if (newId > 0) {
        await loadEvents(); // Refresh the list from DB
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to add event: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateEvent(Event event) async {
    try {
      final rowsAffected = await DatabaseHelper.instance.updateEvent(event.id!, event.toMapForDb());
      if (rowsAffected > 0) {
        await loadEvents(); // Refresh the list from DB
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update event: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteEvent(int id) async {
    try {
      final rowsAffected = await DatabaseHelper.instance.deleteEvent(id);
      if (rowsAffected > 0) {
        await loadEvents(); // Refresh the list from DB
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete event: ${e.toString()}');
      return false;
    }
  }

  // --- YOUR ORIGINAL METHODS ARE BELOW ---

  Future<void> refreshEvents() async {
    await loadEvents();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void searchEvents(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    // This is your original filter logic
    _filteredEvents = _events.where((event) {
      // Category filter
      bool categoryMatch = _selectedCategory == 'All' || event.category == _selectedCategory;

      // Search filter
      bool searchMatch = _searchQuery.isEmpty ||
          event.title.toLowerCase().contains(_searchQuery) ||
          event.description.toLowerCase().contains(_searchQuery) ||
          event.location.toLowerCase().contains(_searchQuery) ||
          event.category.toLowerCase().contains(_searchQuery);

      return categoryMatch && searchMatch;
    }).toList();
  }

  void clearFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    _filteredEvents = List.from(_events);
    notifyListeners();
  }

  Future<bool> joinEvent(int userId, int eventId) async {
    try {
      final success = await DatabaseHelper.instance.joinEvent(userId, eventId);
      if (success) {
        await loadEvents(); // Use loadEvents for consistency
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to join event: ${e.toString()}');
      return false;
    }
  }

  Future<bool> leaveEvent(int userId, int eventId) async {
    try {
      final success = await DatabaseHelper.instance.leaveEvent(userId, eventId);
      if (success) {
        await loadEvents(); // Use loadEvents for consistency
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to leave event: ${e.toString()}');
      return false;
    }
  }

  Future<bool> isUserRegisteredForEvent(int userId, int eventId) async {
    try {
      return await DatabaseHelper.instance.isUserRegisteredForEvent(userId, eventId);
    } catch (e) {
      return false;
    }
  }

  Future<List<Event>> getUserEvents(int userId) async {
    try {
      final eventsData = await DatabaseHelper.instance.getUserEvents(userId);
      return eventsData.map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      _setError('Failed to load user events: ${e.toString()}');
      return [];
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String? error) {
    _error = error;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
