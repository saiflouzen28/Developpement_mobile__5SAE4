import 'package:bcrypt/bcrypt.dart';
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
    print('Database path: $path'); // Add this line
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    // Create users table
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nom TEXT NOT NULL,
      prenom TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      numtel TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''');

    // Create events table
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

    // Create user_events junction table for event registration
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

    // Insert sample events
    await _insertSampleEvents(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create events table if upgrading from version 1
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
  }

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
      await db.insert('events', event);
    }
  }

  // User authentication methods
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
      if (BCrypt.checkpw(password, hashedPassword)) {
        return res.first;
      }
    }
    return null;
  }

  // Event methods
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

  // Event registration methods
  Future<bool> joinEvent(int userId, int eventId) async {
    final db = await instance.database;
    
    try {
      await db.transaction((txn) async {
        // Check if user is already registered
        final existing = await txn.query(
          'user_events',
          where: 'user_id = ? AND event_id = ?',
          whereArgs: [userId, eventId],
        );
        
        if (existing.isNotEmpty) {
          throw Exception('User already registered for this event');
        }

        // Check event capacity
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

        // Register user for event
        await txn.insert('user_events', {
          'user_id': userId,
          'event_id': eventId,
        });

        // Update event participant count
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
        // Remove user registration
        final deleted = await txn.delete(
          'user_events',
          where: 'user_id = ? AND event_id = ?',
          whereArgs: [userId, eventId],
        );
        
        if (deleted == 0) {
          throw Exception('User not registered for this event');
        }

        // Update event participant count
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
  // Add this method inside your DatabaseHelper class

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await instance.database;
    final res = await db.query(    'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

}