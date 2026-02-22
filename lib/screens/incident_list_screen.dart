import 'dart:io';

import 'package:flutter/material.dart';

import '../repositories/incident_report_repo.dart';
import '../widgets/home_back.dart';

class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({super.key});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final repo = IncidentReportRepo();

  bool loading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final data = await repo.getAllJoin();
    if (!mounted) return;
    setState(() {
      items = data;
      loading = false;
    });
  }

  Future<void> _confirmDelete(int index) async {
    final row = items[index];
    final reportId = row['report_id'] as int;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final deleted = await repo.deleteById(reportId);
    if (!mounted) return;

    if (deleted > 0) {
      setState(() => items.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: buildAppBarWithHome('Incident List', context),
      body: items.isEmpty
          ? const Center(child: Text('No incident reports'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final row = items[i];
                final stationName = (row['station_name'] ?? '').toString();
                final typeName = (row['type_name'] ?? '').toString();
                final timestamp = (row['timestamp'] ?? '').toString();
                final description = (row['description'] ?? '').toString();
                final level = (row['severity'] ?? '').toString();

                return ListTile(
                  leading: _thumb(row['evidence_photo'] as String?),
                  title: Text('Polling Station: $stationName'),
                  subtitle: Text(
                    'Violation Type: $typeName\n$timestamp\n$description\nSeverity: $level',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Delete report',
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(i),
                  ),
                );
              },
            ),
    );
  }

  Widget _thumb(String? path) {
    if (path == null || path.trim().isEmpty) {
      return const CircleAvatar(child: Icon(Icons.image_not_supported));
    }

    final file = File(path);
    if (!file.existsSync()) {
      return const CircleAvatar(child: Icon(Icons.broken_image));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(file, width: 54, height: 54, fit: BoxFit.cover),
    );
  }
}

