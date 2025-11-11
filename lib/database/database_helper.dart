import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('elearning.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print('Database path: $path');
    // Version remains 3 as we are not changing the schema, just adding methods
    return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    // 2. ADD 'isAdmin' COLUMN TO THE TABLE DEFINITION
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nom TEXT NOT NULL,
      prenom TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      numtel TEXT,
      isAdmin INTEGER NOT NULL DEFAULT 0, -- 0 for normal user, 1 for admin
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''');

    // 3. CREATE THE ADMIN USER RIGHT AFTER THE TABLE IS CREATED
    await _createAdminUser(db);

    // The rest of your table creation logic is UNCHANGED
    await db.execute('''
    CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      image_url TEXT,
      location TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      event_date TEXT NOT NULL,
      event_time TEXT NOT NULL,
      max_participants INTEGER NOT NULL,
      current_participants INTEGER DEFAULT 0,
      category TEXT NOT NULL,
      created_by INTEGER,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (created_by) REFERENCES users (id)
    )
    ''');

    await db.execute('''
    CREATE TABLE user_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      event_id INTEGER NOT NULL,
      registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
      UNIQUE(user_id, event_id)
    )
    ''');

    // Create quizzes table
    await db.execute('''
    CREATE TABLE quizzes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      total_questions INTEGER NOT NULL,
      duration_minutes INTEGER NOT NULL,
      category TEXT,          -- new column for quiz category
      difficulty TEXT,        -- new column for quiz difficulty (e.g., Easy, Medium, Hard)
      created_by INTEGER,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (created_by) REFERENCES users (id)
    )
    ''');


    // Create questions table
    await db.execute('''
    CREATE TABLE questions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      quiz_id INTEGER NOT NULL,
      question_text TEXT NOT NULL,
      option_a TEXT NOT NULL,
      option_b TEXT NOT NULL,
      option_c TEXT,
      option_d TEXT,
      correct_option TEXT NOT NULL,  -- store 'A', 'B', 'C', or 'D'
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (quiz_id) REFERENCES quizzes (id) ON DELETE CASCADE
    )
    ''');

      await db.execute('''
      CREATE TABLE user_quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        quiz_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        percentage REAL NOT NULL,
        passed BOOLEAN NOT NULL,
        taken_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (quiz_id) REFERENCES quizzes (id) ON DELETE CASCADE
      )
      ''');



    // Insert sample events
    await _insertSampleEvents(db);
    await _insertSampleQuizzes(db);
  }

  // 4. ADD THIS HELPER FUNCTION TO CREATE THE ADMIN
  Future<void> _createAdminUser(Database db) async {
    const adminEmail = 'admin@gmail.com';
    const adminPassword = 'admin123';

    // Check if admin exists to prevent errors on multiple runs
    final existingAdmin = await db.query('users', where: 'email = ?', whereArgs: [adminEmail]);

    if (existingAdmin.isEmpty) {
      final hashedPassword = BCrypt.hashpw(adminPassword, BCrypt.gensalt());
      await db.insert('users', {
        'nom': 'Admin',
        'prenom': 'User',
        'email': adminEmail,
        'password': hashedPassword,
        'numtel': '00000000',
        'isAdmin': 1, // This makes the user an admin
      });
      print('Admin user (admin@gmail.com) created successfully.');
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Your original upgrade logic for version 2, UNCHANGED
      await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        image_url TEXT,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        event_date TEXT NOT NULL,
        event_time TEXT NOT NULL,
        max_participants INTEGER NOT NULL,
        current_participants INTEGER DEFAULT 0,
        category TEXT NOT NULL,
        created_by INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
      ''');

      await db.execute('''
      CREATE TABLE user_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        event_id INTEGER NOT NULL,
        registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
        UNIQUE(user_id, event_id)
      )
      ''');

      await _insertSampleEvents(db);
    }

    // 5. ADD UPGRADE LOGIC FOR VERSION 3
    if (oldVersion < 3) {
      // Use a try-catch block to prevent crashes if the column already exists
      try {
        await db.execute('ALTER TABLE users ADD COLUMN isAdmin INTEGER NOT NULL DEFAULT 0;');
      } catch (e) {
        print('Could not add isAdmin column, it might already exist. Error: $e');
      }
      // Ensure the admin user is created on upgrade as well
      await _createAdminUser(db);
    }
  }

  // YOUR ORIGINAL, COMPLETE _insertSampleEvents METHOD, UNCHANGED.
  Future _insertSampleEvents(Database db) async {
    final sampleEvents = [
      {
        'title': 'Flutter Development Workshop',
        'description': 'Learn Flutter from scratch and build amazing mobile applications. This comprehensive workshop covers everything from basic widgets to advanced state management.',
        'image_url': 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=500',
        'location': 'Tech Hub, Downtown',
        'latitude': 40.7128,
        'longitude': -74.0060,
        'event_date': '2025-10-15',
        'event_time': '10:00',
        'max_participants': 50,
        'current_participants': 23,
        'category': 'Development',
        'created_by': 1
      },
      {
        'title': 'Data Science Bootcamp',
        'description': 'Master data science concepts including machine learning, statistical analysis, and data visualization. Perfect for beginners and intermediate learners.',
        'image_url': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=500',
        'location': 'Innovation Center',
        'latitude': 40.7589,
        'longitude': -73.9851,
        'event_date': '2025-10-20',
        'event_time': '14:00',
        'max_participants': 30,
        'current_participants': 15,
        'category': 'Data Science',
        'created_by': 1
      },
      {
        'title': 'UI/UX Design Masterclass',
        'description': 'Create stunning user interfaces and experiences. Learn design principles, prototyping, and user research techniques from industry experts.',
        'image_url': 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=500',
        'location': 'Design Studio, Creative District',
        'latitude': 40.7489,
        'longitude': -73.9680,
        'event_date': '2025-10-25',
        'event_time': '09:30',
        'max_participants': 25,
        'current_participants': 18,
        'category': 'Design',
        'created_by': 1
      },
      {
        'title': 'Digital Marketing Summit',
        'description': 'Explore the latest trends in digital marketing, social media strategies, and growth hacking techniques to boost your business online presence.',
        'image_url': 'https://images.unsplash.com/photo-1553877522-6494745c1044?w=500',
        'location': 'Business Center, Financial District',
        'latitude': 40.7074,
        'longitude': -74.0113,
        'event_date': '2025-11-01',
        'event_time': '11:00',
        'max_participants': 100,
        'current_participants': 45,
        'category': 'Marketing',
        'created_by': 1
      },
      {
        'title': 'Blockchain Technology Seminar',
        'description': 'Understand blockchain fundamentals, cryptocurrency, and decentralized applications. Get hands-on experience with smart contract development.',
        'image_url': 'https://images.unsplash.com/photo-1639322537228-f710d846310a?w=500',
        'location': 'Tech Park, Silicon Valley',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'event_date': '2025-11-05',
        'event_time': '15:00',
        'max_participants': 40,
        'current_participants': 12,
        'category': 'Technology',
        'created_by': 1
      },
      {
        'title': 'Artificial Intelligence Workshop',
        'description': 'Dive into AI and machine learning with practical projects. Learn neural networks, natural language processing, and computer vision applications.',
        'image_url': 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=500',
        'location': 'AI Research Center',
        'latitude': 37.4419,
        'longitude': -122.1430,
        'event_date': '2025-11-10',
        'event_time': '13:00',
        'max_participants': 35,
        'current_participants': 28,
        'category': 'AI',
        'created_by': 1
      }
    ];

    for (final event in sampleEvents) {
      // Use ignore to prevent crashes if the events are already there from a previous install
      await db.insert('events', event, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
  Future _insertSampleQuizzes(Database db) async {
    final sampleQuizzes = [
      {
        'title': 'Flutter Basics',
        'description': 'Test your knowledge of Flutter widgets and layouts.',
        'total_questions': 10,
        'duration_minutes': 15,
        'category': 'Programming',
        'difficulty': 'Easy',
        'created_by': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Data Science Fundamentals',
        'description': 'A short quiz to assess your understanding of key data science concepts.',
        'total_questions': 8,
        'duration_minutes': 20,
        'category': 'Data Science',
        'difficulty': 'Medium',
        'created_by': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': 'UI/UX Design Quiz',
        'description': 'Check your grasp on UI/UX principles and design patterns.',
        'total_questions': 12,
        'duration_minutes': 25,
        'category': 'Design',
        'difficulty': 'Medium',
        'created_by': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Machine Learning Essentials',
        'description': 'How much do you know about supervised and unsupervised learning?',
        'total_questions': 15,
        'duration_minutes': 30,
        'category': 'AI/ML',
        'difficulty': 'Hard',
        'created_by': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Cybersecurity Awareness',
        'description': 'Evaluate your knowledge about cybersecurity best practices.',
        'total_questions': 7,
        'duration_minutes': 10,
        'category': 'Security',
        'difficulty': 'Easy',
        'created_by': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Cloud Computing Overview',
        'description': 'A quick quiz about cloud models, AWS, and distributed systems.',
        'total_questions': 9,
        'duration_minutes': 20,
        'category': 'Cloud',
        'difficulty': 'Medium',
        'created_by': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final quiz in sampleQuizzes) {
      await db.insert('quizzes', quiz);
    }

    print('✅ Sample quizzes inserted successfully');
  }


  // --- ALL OTHER METHODS ARE UNCHANGED FROM YOUR ORIGINAL FILE ---

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<Map<String, dynamic>?> getUserByPhone(String numtel) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      where: 'numtel = ?',
      whereArgs: [numtel],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> registerUser(String nom, String prenom, String email, String password, String numtel) async {
    final db = await instance.database;
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
    // Normal users are inserted with the default isAdmin value of 0.
    return await db.insert('users', {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': hashedPassword,
      'numtel': numtel,
    });
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (res.isNotEmpty) {
      final hashedPassword = res.first['password'] as String;
      // The 'isAdmin' flag is returned here along with all other user data.
      if (BCrypt.checkpw(password, hashedPassword)) {
        return res.first;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final db = await instance.database;
    return await db.query('events', orderBy: 'event_date ASC, event_time ASC');
  }

  Future<List<Map<String, dynamic>>> getEventsByCategory(String category) async {
    final db = await instance.database;
    return await db.query(
        'events',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'event_date ASC, event_time ASC'
    );
  }

  Future<Map<String, dynamic>?> getEventById(int eventId) async {
    final db = await instance.database;
    final res = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<bool> joinEvent(int userId, int eventId) async {
    final db = await instance.database;
    try {
      await db.transaction((txn) async {
        final existing = await txn.query(
          'user_events',
          where: 'user_id = ? AND event_id = ?',
          whereArgs: [userId, eventId],
        );
        if (existing.isNotEmpty) {
          throw Exception('User already registered for this event');
        }
        final event = await txn.query(
          'events',
          where: 'id = ?',
          whereArgs: [eventId],
        );
        if (event.isEmpty) {
          throw Exception('Event not found');
        }
        final currentParticipants = event.first['current_participants'] as int;
        final maxParticipants = event.first['max_participants'] as int;
        if (currentParticipants >= maxParticipants) {
          throw Exception('Event is full');
        }
        await txn.insert('user_events', {
          'user_id': userId,
          'event_id': eventId,
        });
        await txn.update(
          'events',
          {'current_participants': currentParticipants + 1},
          where: 'id = ?',
          whereArgs: [eventId],
        );
      });
      return true;
    } catch (e) {
      print('Error joining event: $e');
      return false;
    }
  }

  Future<bool> leaveEvent(int userId, int eventId) async {
    final db = await instance.database;
    try {
      await db.transaction((txn) async {
        final deleted = await txn.delete(
          'user_events',
          where: 'user_id = ? AND event_id = ?',
          whereArgs: [userId, eventId],
        );
        if (deleted == 0) {
          throw Exception('User not registered for this event');
        }
        final event = await txn.query(
          'events',
          where: 'id = ?',
          whereArgs: [eventId],
        );
        if (event.isNotEmpty) {
          final currentParticipants = event.first['current_participants'] as int;
          await txn.update(
            'events',
            {'current_participants': currentParticipants - 1},
            where: 'id = ?',
            whereArgs: [eventId],
          );
        }
      });
      return true;
    } catch (e) {
      print('Error leaving event: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserEvents(int userId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT e.*, ue.registered_at 
      FROM events e
      INNER JOIN user_events ue ON e.id = ue.event_id
      WHERE ue.user_id = ?
      ORDER BY e.event_date ASC, e.event_time ASC
    ''', [userId]);
  }

  Future<bool> isUserRegisteredForEvent(int userId, int eventId) async {
    final db = await instance.database;
    final res = await db.query(
      'user_events',
      where: 'user_id = ? AND event_id = ?',
      whereArgs: [userId, eventId],
    );
    return res.isNotEmpty;
  }

  Future<List<String>> getEventCategories() async {
    final db = await instance.database;
    final res = await db.rawQuery('SELECT DISTINCT category FROM events ORDER BY category');
    return res.map((e) => e['category'] as String).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // --- NEW METHODS FOR EVENT CRUD ---

  Future<int> addEvent(Map<String, dynamic> eventData) async {
    final db = await instance.database;
    return await db.insert('events', eventData);
  }

  Future<int> updateEvent(int id, Map<String, dynamic> eventData) async {
    final db = await instance.database;
    return await db.update(
      'events',
      eventData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await instance.database;
    // Also deletes registrations for this event due to ON DELETE CASCADE
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- NEW METHOD FOR ADMIN STATISTICS: Events Per User ---
  Future<List<Map<String, dynamic>>> getEventsPerUser() async {
    final db = await database;
    // This SQL query joins the users table with the user_events table,
    // groups the results by user, and counts the number of events for each.
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT
        U.id,
        U.prenom,
        U.nom,
        U.email,
        COUNT(UE.event_id) as event_count
      FROM users U
      LEFT JOIN user_events UE ON U.id = UE.user_id
      WHERE U.isAdmin = 0 -- Exclude admin from the list
      GROUP BY U.id
      ORDER BY event_count DESC, U.prenom ASC
    ''');
    return result;
  }

  // --- NEW METHOD FOR ADMIN STATISTICS: Earnings Per Event ---
  Future<List<Map<String, dynamic>>> getEarningsPerEvent() async {
    final db = await database;
    // This uses the fixed price of 50 coins for the calculation.
    const coinPrice = 50;

    // This query gets each event and calculates its earnings by multiplying
    // the participant count by the fixed coin price.
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT
        id,
        title,
        category,
        current_participants,
        (current_participants * ?) as earnings
      FROM events
      WHERE current_participants > 0
      ORDER BY earnings DESC, title ASC
    ''', [coinPrice]);
    return result;
  }
// Add this at the end of DatabaseHelper class
  Future<String?> exportStatisticsToCsv() async {
    try {
      final db = await database;

      // 1. Total Earnings
      final totalRes = await db.rawQuery(
          'SELECT SUM(current_participants * 50) as total FROM events WHERE current_participants > 0');
      final totalEarnings = totalRes.first['total'] as int? ?? 0;

      // 2. Total Users (non-admin)
      final userCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE isAdmin = 0');
      final totalUsers = userCountRes.first['count'] as int;

      // 3. Avg per user
      final avgPerUser = totalUsers > 0 ? (totalEarnings / totalUsers).round() : 0;

      // 4. Events per user
      final usersData = await db.rawQuery('''
      SELECT u.prenom, u.nom, u.email, COUNT(ue.event_id) as events
      FROM users u
      LEFT JOIN user_events ue ON u.id = ue.user_id
      WHERE u.isAdmin = 0
      GROUP BY u.id
      ORDER BY events DESC
    ''');

      // 5. Earnings per event
      final eventsData = await db.rawQuery('''
      SELECT title, category, current_participants, (current_participants * 50) as earnings
      FROM events
      WHERE current_participants > 0
      ORDER BY earnings DESC
    ''');

      // Build CSV
      final csv = <List<dynamic>>[];

      // Header
      csv.add(['E-Learning Platform Statistics']);
      csv.add(['Generated on', DateTime.now().toString()]);
      csv.add([]);

      // Summary
      csv.add(['SUMMARY']);
      csv.add(['Total Earnings (coins)', totalEarnings]);
      csv.add(['Total Users', totalUsers]);
      csv.add(['Avg Coins per User', avgPerUser]);
      csv.add([]);

      // Events per User
      csv.add(['EVENTS PER USER']);
      csv.add(['First Name', 'Last Name', 'Email', 'Events Joined']);
      for (var u in usersData) {
        csv.add([u['prenom'], u['nom'], u['email'], u['events']]);
      }
      csv.add([]);

      // Earnings per Event
      csv.add(['EARNINGS PER EVENT']);
      csv.add(['Title', 'Category', 'Participants', 'Earnings (coins)']);
      for (var e in eventsData) {
        csv.add([e['title'], e['category'], e['current_participants'], e['earnings']]);
      }

      // Convert to string
      final csvString = const ListToCsvConverter().convert(csv);

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/stats_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvString);

      return file.path; // Return path to show in UI
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }
  // ---------------------- QUIZZES METHODS ----------------------

  /// Add a new quiz
  Future<bool> addQuiz(Map<String, dynamic> quiz) async {
    try {
      final db = await database;
      await db.insert('quizzes', quiz);
      print('✅ Quiz added successfully: $quiz');
      return true;
    } catch (e) {
      print('Add quiz error: $e');
      return false;
    }
  }

  /// Add a new quiz and return the inserted row id (or null on failure)
  Future<int?> addQuizReturnId(Map<String, dynamic> quiz) async {
    try {
      print('DB: addQuizReturnId called with map: $quiz');
      final db = await database;
      final id = await db.insert('quizzes', quiz);
      print('✅ Quiz added with id $id: $quiz');
      return id;
    } catch (e, st) {
      // Log full error and stacktrace to help debugging when insert fails
      print('Add quiz error: $e');
      print('Stacktrace: $st');
      return null;
    }
  }

  /// Get all quizzes (latest first)
  Future<List<Map<String, dynamic>>> getAllQuizzes() async {
    final db = await database;
    return await db.query(
      'quizzes',
      orderBy: 'created_at DESC',
    );
  }

  /// Get a specific quiz by ID
  Future<Map<String, dynamic>?> getQuizById(int id) async {
    final db = await database;
    final result = await db.query(
      'quizzes',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Update a quiz
  Future<bool> updateQuiz(Map<String, dynamic> quiz) async {
    try {
      final db = await database;
      await db.update(
        'quizzes',
        quiz,
        where: 'id = ?',
        whereArgs: [quiz['id']],
      );
      print('✅ Quiz updated: ${quiz['title']}');
      return true;
    } catch (e) {
      print('Update quiz error: $e');
      return false;
    }
  }

  /// Delete a quiz
  Future<bool> deleteQuiz(int quizId) async {
    try {
      final db = await database;
      await db.delete('quizzes', where: 'id = ?', whereArgs: [quizId]);
      print('🗑️ Quiz deleted: $quizId');
      return true;
    } catch (e) {
      print('Delete quiz error: $e');
      return false;
    }
  }
// ---------------------- QUESTIONS METHODS ----------------------

  /// Add a question
  Future<bool> addQuestion(Map<String, dynamic> question) async {
    try {
      final db = await database;
      await db.insert('questions', question);
      print('✅ Question added successfully: $question');
      return true;
    } catch (e) {
      print('Add question error: $e');
      return false;
    }
  }

  /// Get all questions for a specific quiz
  Future<List<Map<String, dynamic>>> getQuestionsByQuiz(int quizId) async {
    final db = await database;
    return await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'created_at DESC',
    );
  }

  /// Update a question
  Future<bool> updateQuestion(Map<String, dynamic> question) async {
    try {
      final db = await database;
      await db.update(
        'questions',
        question,
        where: 'id = ?',
        whereArgs: [question['id']],
      );
      print('✅ Question updated: ${question['question_text']}');
      return true;
    } catch (e) {
      print('Update question error: $e');
      return false;
    }
  }

  /// Delete a question
  Future<bool> deleteQuestion(int questionId) async {
    try {
      final db = await database;
      await db.delete('questions', where: 'id = ?', whereArgs: [questionId]);
      print('🗑️ Question deleted: $questionId');
      return true;
    } catch (e) {
      print('Delete question error: $e');
      return false;
    }
  }
  /// Save a user quiz result
  static Future<bool> saveQuizResult({
    required int userId,
    required int quizId,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      final db = await instance.database;

      // Calculate percentage
      double percentage = (score / totalQuestions) * 100;

      // Determine if the user passed (>=50%)
      bool passed = percentage >= 50;

      await db.insert(
        'user_quiz_results',
        {
          'user_id': userId,
          'quiz_id': quizId,
          'score': score,
          'percentage': percentage,
          'passed': passed ? 1 : 0,
          'taken_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Quiz result saved: user $userId, quiz $quizId, score $score/$totalQuestions');
      return true;
    } catch (e) {
      print('❌ Save quiz result error: $e');
      return false;
    }
  }

  /// Fetch quiz history for a user
  static Future<List<Map<String, dynamic>>> getUserQuizResults(int userId) async {
    final db = await instance.database;
    return await db.query(
      'user_quiz_results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'taken_at DESC',
    );
  }
}
