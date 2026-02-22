import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'final_2568.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<String> getDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, _dbName);
  }

  Future<bool> dbFileExists() async {
    final path = await getDbPath();
    return File(path).exists();
  }

  Future<Database> _initDb() async {
    final path = await getDbPath();
    final existed = await File(path).exists();

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );

    if (!existed) {
      await _seed(db);
    }

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE polling_station(
        station_id INTEGER PRIMARY KEY,
        station_name TEXT NOT NULL,
        zone TEXT NOT NULL,
        province TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE violation_type(
        type_id INTEGER PRIMARY KEY,
        type_name TEXT NOT NULL,
        severity TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE incident_report(
        report_id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id INTEGER NOT NULL,
        type_id INTEGER NOT NULL,
        reporter_name TEXT,
        description TEXT,
        evidence_photo TEXT,
        timestamp TEXT NOT NULL,
        ai_result TEXT,
        ai_confidence REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY(station_id) REFERENCES polling_station(station_id),
        FOREIGN KEY(type_id) REFERENCES violation_type(type_id)
      );
    ''');
  }

  Future<void> _seed(Database db) async {
    await db.insert('polling_station', {
      'station_id': 101,
      'station_name': 'School Wat Phra Mahathat',
      'zone': 'Zone 1',
      'province': 'Nakhon Si Thammarat',
    });
    await db.insert('polling_station', {
      'station_id': 102,
      'station_name': 'Tent Tha Wang Market Front',
      'zone': 'Zone 1',
      'province': 'Nakhon Si Thammarat',
    });
    await db.insert('polling_station', {
      'station_id': 103,
      'station_name': 'Pavilion Kiriwong Village Center',
      'zone': 'Zone 2',
      'province': 'Nakhon Si Thammarat',
    });
    await db.insert('polling_station', {
      'station_id': 104,
      'station_name': 'Hall Thung Song District Center',
      'zone': 'Zone 3',
      'province': 'Nakhon Si Thammarat',
    });

    await db.insert('violation_type', {
      'type_id': 1,
      'type_name': 'Buying Votes',
      'severity': 'High',
    });
    await db.insert('violation_type', {
      'type_id': 2,
      'type_name': 'Transportation to Polling',
      'severity': 'High',
    });
    await db.insert('violation_type', {
      'type_id': 3,
      'type_name': 'Overtime Campaign',
      'severity': 'Medium',
    });
    await db.insert('violation_type', {
      'type_id': 4,
      'type_name': 'Vandalism',
      'severity': 'Low',
    });
    await db.insert('violation_type', {
      'type_id': 5,
      'type_name': 'Bias Official',
      'severity': 'High',
    });

    await db.insert('incident_report', {
      'station_id': 101,
      'type_id': 1,
      'reporter_name': 'Citizen 01',
      'description': 'Observed money distribution near the polling station entrance.',
      'evidence_photo': null,
      'timestamp': '2026-02-08 09:30:00',
      'ai_result': null,
      'ai_confidence': 0.0,
    });
  }

  Future<int> countOfflineIncidentReports() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM incident_report;
    ''');
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> topStationsByReports({
    int limit = 3,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT ps.station_id,
             ps.station_name,
             COUNT(ir.report_id) AS report_count
      FROM incident_report ir
      JOIN polling_station ps ON ps.station_id = ir.station_id
      GROUP BY ps.station_id, ps.station_name
      ORDER BY report_count DESC, ps.station_id ASC
      LIMIT ?;
    ''',
      [limit],
    );
  }
}

