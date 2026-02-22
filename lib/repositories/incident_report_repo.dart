import '../helpers/database_helper.dart';

class IncidentReportRepo {
  Future<int> insert(Map<String, dynamic> payload) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert("incident_report", payload);
  }

  Future<int> deleteById(int reportId) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(
      "incident_report",
      where: "report_id = ?",
      whereArgs: [reportId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllJoin() async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery('''
      SELECT ir.report_id, ir.timestamp, ir.description, ir.reporter_name, ir.evidence_photo,
             ir.ai_result, ir.ai_confidence,
             ps.station_id, ps.station_name,
             vt.type_id, vt.type_name, vt.severity
      FROM incident_report ir
      JOIN polling_station ps ON ps.station_id = ir.station_id
      JOIN violation_type vt ON vt.type_id = ir.type_id
      ORDER BY ir.report_id DESC;
    ''');
  }

  Future<List<Map<String, dynamic>>> searchJoin({
    required String keyword,
    String? severity,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final normalizedKeyword = keyword.trim();
    final kw = "%$normalizedKeyword%";
    final sev = (severity ?? "").trim();

    if (normalizedKeyword.isEmpty && sev.isEmpty) {
      return getAllJoin();
    }

    if (normalizedKeyword.isEmpty && sev.isNotEmpty) {
      return db.rawQuery(
        '''
        SELECT ir.report_id, ir.timestamp, ir.description, ir.reporter_name, ir.evidence_photo,
               ir.ai_result, ir.ai_confidence,
               ps.station_name,
               vt.type_name, vt.severity
        FROM incident_report ir
        JOIN polling_station ps ON ps.station_id = ir.station_id
        JOIN violation_type vt ON vt.type_id = ir.type_id
        WHERE vt.severity = ?
        ORDER BY ir.report_id DESC;
      ''',
        [sev],
      );
    }

    if (sev.isEmpty) {
      return db.rawQuery(
        '''
        SELECT ir.report_id, ir.timestamp, ir.description, ir.reporter_name, ir.evidence_photo,
               ir.ai_result, ir.ai_confidence,
               ps.station_name,
               vt.type_name, vt.severity
        FROM incident_report ir
        JOIN polling_station ps ON ps.station_id = ir.station_id
        JOIN violation_type vt ON vt.type_id = ir.type_id
        WHERE (
          COALESCE(ir.reporter_name, '') LIKE ?
          OR COALESCE(ir.description, '') LIKE ?
          OR COALESCE(ps.station_name, '') LIKE ?
        )
        ORDER BY ir.report_id DESC;
      ''',
        [kw, kw, kw],
      );
    }

    return db.rawQuery(
      '''
      SELECT ir.report_id, ir.timestamp, ir.description, ir.reporter_name, ir.evidence_photo,
             ir.ai_result, ir.ai_confidence,
             ps.station_name,
             vt.type_name, vt.severity
      FROM incident_report ir
      JOIN polling_station ps ON ps.station_id = ir.station_id
      JOIN violation_type vt ON vt.type_id = ir.type_id
      WHERE (
        COALESCE(ir.reporter_name, '') LIKE ?
        OR COALESCE(ir.description, '') LIKE ?
        OR COALESCE(ps.station_name, '') LIKE ?
      )
        AND vt.severity = ?
      ORDER BY ir.report_id DESC;
    ''',
      [kw, kw, kw, sev],
    );
  }
}

