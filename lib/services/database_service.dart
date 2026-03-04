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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scans (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT    NOT NULL,
            diseaseName TEXT  NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pest_scans (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT    NOT NULL,
            pestName  TEXT    NOT NULL,
            timestamp INTEGER NOT NULL
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
      },
    );
  }

  Database get _database {
    if (_db == null) throw StateError('DatabaseService not initialised. Call init() first.');
    return _db!;
  }

  /// Insert a new scan record. Returns the new row id.
  Future<int> insertScan(String imagePath, String diseaseName) async {
    return await _database.insert(
      'scans',
      {
        'imagePath': imagePath,
        'diseaseName': diseaseName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the [limit] most-recent scans, newest first.
  Future<List<Map<String, dynamic>>> getScans({int limit = 20}) async {
    return await _database.query(
      'scans',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  /// Delete a scan by its id.
  Future<void> deleteScan(int id) async {
    await _database.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  // ====== PEST SCANS ======

  /// Insert a new pest scan record. Returns the new row id.
  Future<int> insertPestScan(String imagePath, String pestName) async {
    return await _database.insert(
      'pest_scans',
      {
        'imagePath': imagePath,
        'pestName': pestName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the [limit] most-recent pest scans, newest first.
  Future<List<Map<String, dynamic>>> getPestScans({int limit = 20}) async {
    return await _database.query(
      'pest_scans',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  /// Delete a pest scan by its id.
  Future<void> deletePestScan(int id) async {
    await _database.delete('pest_scans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
