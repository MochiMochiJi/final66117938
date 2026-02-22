import '../helpers/database_helper.dart';

class PollingStationRepo {
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    return db.query("polling_station", orderBy: "station_id ASC");
  }

  Future<Map<String, dynamic>?> getById(int stationId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      "polling_station",
      where: "station_id = ?",
      whereArgs: [stationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> countNameDuplicateExceptId({
    required int stationId,
    required String newName,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS c
      FROM polling_station
      WHERE station_name = ?
        AND station_id != ?;
    ''',
      [newName, stationId],
    );
    return (rows.first["c"] as int?) ?? 0;
  }

  Future<int> countReportsByStation(int stationId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS c
      FROM incident_report
      WHERE station_id = ?;
    ''',
      [stationId],
    );
    return (rows.first["c"] as int?) ?? 0;
  }

  Future<int> updateStation({
    required int stationId,
    required String stationName,
    required String zone,
    required String province,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      "polling_station",
      {"station_name": stationName, "zone": zone, "province": province},
      where: "station_id = ?",
      whereArgs: [stationId],
    );
  }
}

