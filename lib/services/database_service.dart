import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scans.db');

    _db = await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            name      TEXT    NOT NULL,
            phone     TEXT    NOT NULL UNIQUE,
            pin_hash  TEXT    NOT NULL,
            district  TEXT    NOT NULL,
            farm_size REAL    NOT NULL,
            synced    INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE scans (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id   INTEGER NOT NULL,
            imagePath TEXT    NOT NULL,
            diseaseName TEXT  NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pest_scans (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id   INTEGER NOT NULL,
            imagePath TEXT    NOT NULL,
            pestName  TEXT    NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE soil_scans (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id   INTEGER NOT NULL,
            imagePath TEXT    NOT NULL,
            moisture  REAL,
            temperature REAL,
            ec        INTEGER,
            ph        REAL,
            nitrogen  INTEGER,
            phosphorus INTEGER,
            potassium INTEGER,
            soil_score REAL,
            timestamp INTEGER NOT NULL,
            synced    INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE pest_scans (
              id        INTEGER PRIMARY KEY AUTOINCREMENT,
              imagePath TEXT    NOT NULL,
              pestName  TEXT    NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE users (
              id        INTEGER PRIMARY KEY AUTOINCREMENT,
              name      TEXT    NOT NULL,
              phone     TEXT    NOT NULL UNIQUE,
              pin_hash  TEXT    NOT NULL,
              district  TEXT    NOT NULL,
              farm_size REAL    NOT NULL,
              synced    INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute("ALTER TABLE scans ADD COLUMN user_id INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE pest_scans ADD COLUMN user_id INTEGER NOT NULL DEFAULT 0");
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE soil_scans (
              id        INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id   INTEGER NOT NULL,
              imagePath TEXT    NOT NULL,
              moisture  REAL,
              temperature REAL,
              ec        INTEGER,
              ph        REAL,
              nitrogen  INTEGER,
              phosphorus INTEGER,
              potassium INTEGER,
              soil_score REAL,
              timestamp INTEGER NOT NULL,
              synced    INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
      },
    );
  }

  Database get _database {
    if (_db == null) throw StateError('DatabaseService not initialised. Call init() first.');
    return _db!;
  }

  // ====== USERS ======

  Future<int> insertUser(Map<String, dynamic> userMap) async {
    return await _database.insert('users', userMap);
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final results = await _database.query('users', where: 'phone = ?', whereArgs: [phone]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final results = await _database.query('users', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedUsers() async {
    return await _database.query('users', where: 'synced = 0');
  }

  Future<void> markUserSynced(int id) async {
    await _database.update('users', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ====== LEAF SCANS ======

  Future<int> insertScan(int userId, String imagePath, String diseaseName) async {
    return await _database.insert(
      'scans',
      {
        'user_id': userId,
        'imagePath': imagePath,
        'diseaseName': diseaseName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getScans(int userId, {int limit = 20}) async {
    return await _database.query(
      'scans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<void> deleteScan(int id) async {
    await _database.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  // ====== PEST SCANS ======

  Future<int> insertPestScan(int userId, String imagePath, String pestName) async {
    return await _database.insert(
      'pest_scans',
      {
        'user_id': userId,
        'imagePath': imagePath,
        'pestName': pestName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPestScans(int userId, {int limit = 20}) async {
    return await _database.query(
      'pest_scans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<void> deletePestScan(int id) async {
    await _database.delete('pest_scans', where: 'id = ?', whereArgs: [id]);
  }

  // ====== SOIL SCANS ======

  Future<int> insertSoilScan(Map<String, dynamic> scanData) async {
    return await _database.insert(
      'soil_scans',
      scanData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSoilScans(int userId, {int limit = 20}) async {
    return await _database.query(
      'soil_scans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSoilScans() async {
    return await _database.query('soil_scans', where: 'synced = 0');
  }

  Future<void> markSoilScanSynced(int id) async {
    await _database.update('soil_scans', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSoilScan(int id) async {
    await _database.delete('soil_scans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

