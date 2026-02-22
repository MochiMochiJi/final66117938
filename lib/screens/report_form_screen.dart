import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../repositories/incident_report_repo.dart';
import '../repositories/polling_station_repo.dart';
import '../repositories/violation_type_repo.dart';
import '../services/firestore_service.dart';
import '../widgets/home_back.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final stationRepo = PollingStationRepo();
  final typeRepo = ViolationTypeRepo();
  final incidentRepo = IncidentReportRepo();
  final firestore = FirestoreService();

  final reporterCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  List<Map<String, dynamic>> stations = [];
  List<Map<String, dynamic>> types = [];

  int? stationId;
  int? typeId;

  File? pickedImage;

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await stationRepo.getAll();
    final t = await typeRepo.getAll();

    if (!mounted) return;
    setState(() {
      stations = s;
      types = t;
      stationId = s.isNotEmpty ? s.first['station_id'] as int : null;
      typeId = t.isNotEmpty ? t.first['type_id'] as int : null;
      loading = false;
    });
  }

  Future<void> _pickImage(ImageSource src) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: src, imageQuality: 85);
    if (x == null) return;

    setState(() {
      pickedImage = File(x.path);
    });
  }

  String _nowStr() => DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    if (stationId == null || typeId == null) {
      _toast('Please select both polling station and violation type.');
      return;
    }

    setState(() => saving = true);

    final reporter = reporterCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final ts = _nowStr();
    final evidencePath = pickedImage?.path;

    final payload = <String, dynamic>{
      'station_id': stationId,
      'type_id': typeId,
      'reporter_name': reporter.isEmpty ? null : reporter,
      'description': desc.isEmpty ? null : desc,
      'evidence_photo': (evidencePath == null || evidencePath.isEmpty)
          ? null
          : evidencePath,
      'timestamp': ts,
    };

    int insertedId = 0;
    bool onlineOk = true;

    try {
      insertedId = await incidentRepo.insert(payload);
      if (insertedId <= 0) {
        throw Exception('SQLite insert failed.');
      }

      try {
        await firestore.addIncidentOnline(
          stationId: stationId!,
          typeId: typeId!,
          timestamp: ts,
          reporterName: reporter.isEmpty ? null : reporter,
          description: desc.isEmpty ? null : desc,
          evidencePhoto: evidencePath,
        );
      } catch (_) {
        onlineOk = false;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      _toast('Save failed: $e');
      return;
    }

    if (!mounted) return;
    setState(() => saving = false);

    _toast(
      onlineOk
          ? 'Saved successfully (Offline ID=$insertedId + Online OK).'
          : 'Saved to SQLite (Offline ID=$insertedId). Online sync failed.',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: buildAppBarWithHome('Report Incident', context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: stationId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Polling Station',
                border: OutlineInputBorder(),
              ),
              items: stations
                  .map(
                    (s) => DropdownMenuItem(
                      value: s['station_id'] as int,
                      child: Text(
                        "${s['station_id']}. ${s['station_name']}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => stationId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: typeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Violation Type',
                border: OutlineInputBorder(),
              ),
              items: types
                  .map(
                    (t) => DropdownMenuItem(
                      value: t['type_id'] as int,
                      child: Text(
                        "${t['type_id']}. ${t['type_name']}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => typeId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reporterCtrl,
              decoration: const InputDecoration(
                labelText: 'Reporter Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pickedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  pickedImage!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    reporterCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }
}

