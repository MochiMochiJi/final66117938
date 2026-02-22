import '../helpers/database_helper.dart';

class ViolationTypeRepo {
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    return db.query("violation_type", orderBy: "type_id ASC");
  }

  Future<Map<String, dynamic>?> getById(int typeId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      "violation_type",
      where: "type_id = ?",
      whereArgs: [typeId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }
}

