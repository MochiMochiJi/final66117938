import 'package:flutter/material.dart';

import '../repositories/polling_station_repo.dart';
import '../widgets/home_back.dart';

class EditStationFormScreen extends StatefulWidget {
  final int stationId;
  const EditStationFormScreen({super.key, required this.stationId});

  @override
  State<EditStationFormScreen> createState() => _EditStationFormScreenState();
}

class _EditStationFormScreenState extends State<EditStationFormScreen> {
  final repo = PollingStationRepo();

  final nameCtrl = TextEditingController();
  final zoneCtrl = TextEditingController();
  final provinceCtrl = TextEditingController();

  bool loading = true;
  String originalName = '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await repo.getById(widget.stationId);
    if (m == null) {
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    originalName = (m['station_name'] ?? '').toString();
    nameCtrl.text = originalName;
    zoneCtrl.text = (m['zone'] ?? '').toString();
    provinceCtrl.text = (m['province'] ?? '').toString();

    setState(() => loading = false);
  }

  bool _validThaiPrefix(String name) {
    const allowed = ['โรงเรียน', 'วัด', 'เต็นท์', 'ศาลา', 'หอประชุม'];
    return allowed.any((p) => name.startsWith(p));
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final newName = nameCtrl.text.trim();
    final newZone = zoneCtrl.text.trim();
    final newProvince = provinceCtrl.text.trim();
    final nameChanged = newName != originalName;

    if (newName.isEmpty || (nameChanged && !_validThaiPrefix(newName))) {
      _toast(
        'Cannot save: invalid station name format. Must start with โรงเรียน, วัด, เต็นท์, ศาลา, or หอประชุม.',
      );
      return;
    }

    final dup = await repo.countNameDuplicateExceptId(
      stationId: widget.stationId,
      newName: newName,
    );
    if (dup > 0) {
      _toast('Cannot save: duplicate station name already exists.');
      return;
    }

    final count = await repo.countReportsByStation(widget.stationId);

    if (count > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm Edit'),
          content: Text(
            'หน่วยนี้มีประวัติร้องเรียน $count เรื่อง ยืนยันการแก้ไขข้อมูลหรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    final updated = await repo.updateStation(
      stationId: widget.stationId,
      stationName: newName,
      zone: newZone,
      province: newProvince,
    );

    if (!mounted) return;
    _toast(updated > 0 ? 'Saved successfully.' : 'No records were updated.');
    Navigator.pop(context, updated > 0);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: buildAppBarWithHome('Edit Station #${widget.stationId}', context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Station Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: zoneCtrl,
              decoration: const InputDecoration(labelText: 'Zone'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: provinceCtrl,
              decoration: const InputDecoration(labelText: 'Province'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    zoneCtrl.dispose();
    provinceCtrl.dispose();
    super.dispose();
  }
}

