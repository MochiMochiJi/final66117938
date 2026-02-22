import 'package:flutter/material.dart';

import '../repositories/polling_station_repo.dart';
import '../widgets/home_back.dart';
import 'edit_station_form_screen.dart';

class EditStationListScreen extends StatefulWidget {
  const EditStationListScreen({super.key});

  @override
  State<EditStationListScreen> createState() => _EditStationListScreenState();
}

class _EditStationListScreenState extends State<EditStationListScreen> {
  final repo = PollingStationRepo();
  bool loading = true;
  List<Map<String, dynamic>> stations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await repo.getAll();
    final withCounts = await Future.wait(
      rows.map((s) async {
        final stationId = s['station_id'] as int;
        final reportCount = await repo.countReportsByStation(stationId);
        return {
          ...s,
          'report_count': reportCount,
        };
      }),
    );
    if (!mounted) return;
    setState(() {
      stations = withCounts;
      loading = false;
    });
  }

  Future<void> _openEdit(int stationId) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditStationFormScreen(stationId: stationId),
      ),
    );

    if (changed == true) {
      setState(() => loading = true);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: buildAppBarWithHome('Edit Polling Station', context),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          itemCount: stations.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final s = stations[i];
            final reportCount = (s['report_count'] ?? 0) as int;
            return ListTile(
              title: Text("${s['station_id']}. ${s['station_name']}"),
              subtitle: Text(
                "${s['zone']} • ${s['province']} • Reports: $reportCount",
              ),
              onTap: () => _openEdit(s['station_id'] as int),
            );
          },
        ),
      ),
    );
  }
}

