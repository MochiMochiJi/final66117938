import 'dart:io';

import 'package:flutter/material.dart';

import '../repositories/incident_report_repo.dart';
import '../widgets/home_back.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final repo = IncidentReportRepo();
  final searchCtrl = TextEditingController();

  String severity = '';
  bool loading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _applySearch();
  }

  Future<void> _applySearch() async {
    setState(() => loading = true);
    final kw = searchCtrl.text.trim();
    final data = (kw.isEmpty && severity.isEmpty)
        ? await repo.getAllJoin()
        : await repo.searchJoin(keyword: kw, severity: severity);

    if (!mounted) return;
    setState(() {
      items = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: buildAppBarWithHome('Search & Filter (Offline)', context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Search (Reporter / Description / Station)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _applySearch,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _applySearch(),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Severity',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                  ],
                  onChanged: (v) {
                    severity = v ?? '';
                    _applySearch();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No records found'))
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
                      );
                    },
                  ),
          ),
        ],
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

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }
}

