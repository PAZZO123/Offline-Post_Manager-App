// lib/database/database_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/post.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName    = 'posts_manager.db';
  static const int    _dbVersion = 2; // bumped to 2 to add users table
  static const String _postsTable = 'posts';
  static const String _usersTable = 'users';

  // ─── Open ─────────────────────────────────────────────────────────────────

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path   = join(dbPath, _dbName);
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception('Failed to initialise database: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // posts table
    await db.execute('''
      CREATE TABLE $_postsTable (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        title     TEXT    NOT NULL,
        body      TEXT    NOT NULL,
        author    TEXT    NOT NULL,
        createdAt TEXT    NOT NULL
      )
    ''');
    // users table
    await db.execute('''
      CREATE TABLE $_usersTable (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        username     TEXT    NOT NULL UNIQUE,
        passwordHash TEXT    NOT NULL,
        createdAt    TEXT    NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_usersTable (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          username     TEXT    NOT NULL UNIQUE,
          passwordHash TEXT    NOT NULL,
          createdAt    TEXT    NOT NULL
        )
      ''');
    }
  }

  // ─── USER CRUD ────────────────────────────────────────────────────────────

  Future<int> insertUser(User user) async {
    try {
      final db = await database;
      return await db.insert(
        _usersTable,
        user.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Username already exists');
      }
      throw Exception('Register failed — ${e.result ?? e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error during register: $e');
    }
  }

  Future<User?> getUserByUsername(String username) async {
    try {
      final db   = await database;
      final maps = await db.query(
        _usersTable,
        where: 'username = ?',
        whereArgs: [username.trim()],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return User.fromMap(maps.first);
    } on DatabaseException catch (e) {
      throw Exception('Login query failed — ${e.result ?? e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error during login: $e');
    }
  }

  // ─── POST CRUD ────────────────────────────────────────────────────────────

  Future<int> insertPost(Post post) async {
    try {
      final db = await database;
      return await db.insert(
        _postsTable,
        post.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw Exception('Insert failed — ${e.result ?? e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error during insert: $e');
    }
  }

  Future<List<Post>> getAllPosts() async {
    try {
      final db   = await database;
      final maps = await db.query(_postsTable, orderBy: 'id DESC');
      return maps.map((m) => Post.fromMap(m)).toList();
    } on DatabaseException catch (e) {
      throw Exception('Query failed — ${e.result ?? e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error during query: $e');
    }
  }

  Future<Post?> getPostById(int id) async {
    try {
      final db   = await database;
      final maps = await db.query(
        _postsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Post.fromMap(maps.first);
    } on DatabaseException catch (e) {
      throw Exception('Query by id failed — ${e.result ?? e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error during getPostById: $e');
    }
  }

  Future<int> updatePost(Post post) async {
    if (post.id == null) throw Exception('Cannot update a post with no id');
    try {
      final db = await database;
      return await db.update(
        _postsTable,
        post.toMap(),
        where: 'id = ?',
        whereArgs: [post.id],
      );
    } on DatabaseException catch (e) {
      throw Exception('Update failed — ${e.result ?? e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error during update: $e');
    }
  }

  Future<int> deletePost(int id) async {
    try {
      final db = await database;
      return await db.delete(
        _postsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e) {
      throw Exception('Delete failed — ${e.result ?? e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error during delete: $e');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}