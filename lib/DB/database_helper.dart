import 'package:bcrypt/bcrypt.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {

    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nom TEXT NOT NULL,
      prenom TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      numtel TEXT
    )
    ''');
  }




  // récupère l'utilisateur par email
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
    return await db.insert('users', {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': password,
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
      if (BCrypt.checkpw(password, hashedPassword)) { // comparer le hash
        return res.first;
      }
    }
    return null;
  }


  Future<int> updatePassword(String email, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }



}