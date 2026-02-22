import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> addIncidentOnline({
    required int stationId,
    required int typeId,
    required String timestamp,
    String? reporterName,
    String? description,
    String? evidencePhoto,
  }) async {
    String? uploadablePhoto;

    if (evidencePhoto == null || evidencePhoto.trim().isEmpty) {
      uploadablePhoto = null;
    } else {
      final p = evidencePhoto.trim();
      final isHttp = p.startsWith("http://") || p.startsWith("https://");
      uploadablePhoto = isHttp ? p : "OFFLINE_ONLY";
    }

    await _db.collection("incident_reports").add({
      "station_id": stationId,
      "type_id": typeId,
      "timestamp": timestamp,
      "reporter_name": reporterName,
      "description": description,
      "evidence_photo": uploadablePhoto,
      "created_at": FieldValue.serverTimestamp(),
    });
  }
}

