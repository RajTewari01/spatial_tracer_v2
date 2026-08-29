import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spatial_tracer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE tracking_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  start_time TEXT NOT NULL,
  end_time TEXT
)
''');
  }

  Future<int> startSession(DateTime startTime) async {
    final db = await instance.database;
    return await db.insert('tracking_sessions', {
      'start_time': startTime.toIso8601String(),
    });
  }

  Future<int> endSession(int id, DateTime endTime) async {
    final db = await instance.database;
    return await db.update(
      'tracking_sessions',
      {'end_time': endTime.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getLastSession() async {
    final db = await instance.database;
    final maps = await db.query(
      'tracking_sessions',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final db = await instance.database;
    final maps = await db.query(
      'tracking_sessions',
      where: 'end_time IS NULL',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<Map<String, dynamic>?> getLastCompletedSession() async {
    final db = await instance.database;
    final maps = await db.query(
      'tracking_sessions',
      where: 'end_time IS NOT NULL',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }
}
