import 'package:flutter/material.dart';
import '../constants/app_routes.dart';
import '../helpers/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String dbStatus = 'Checking...';
  int offlineTotal = 0;
  List<Map<String, dynamic>> topStations = [];
  bool loadingSummary = true;

  @override
  void initState() {
    super.initState();
    _checkDb();
  }

  Future<void> _checkDb() async {
    final existed = await DatabaseHelper.instance.dbFileExists();
    await DatabaseHelper.instance.database;
    final total = await DatabaseHelper.instance.countOfflineIncidentReports();
    final top = await DatabaseHelper.instance.topStationsByReports(limit: 3);

    if (!mounted) return;
    setState(() {
      dbStatus = existed ? 'DB: Ready' : 'DB: Created and seeded';
      offlineTotal = total;
      topStations = top;
      loadingSummary = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home (Dashboard)')),
      body: RefreshIndicator(
        onRefresh: _checkDb,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(dbStatus),
            const SizedBox(height: 12),
            if (loadingSummary)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else ...[
              Text('Offline incident reports: $offlineTotal'),
              const SizedBox(height: 8),
              const Text(
                'Top 3 most reported polling stations',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (topStations.isEmpty)
                const Text('- No incident reports yet')
              else
                ...topStations.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final row = entry.value;
                  final name = (row['station_name'] ?? '-').toString();
                  final count = row['report_count'] ?? 0;
                  return Text('$rank. $name ($count reports)');
                }),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.reportForm),
              child: const Text(
                'Report Incident',
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.editStationList),
              child: const Text(
                'Edit Polling Station',
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.incidentList),
              child: const Text(
                'Incident List',
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.searchFilter),
              child: const Text('Search & Filter'),
            ),
          ],
        ),
      ),
    );
  }
}

