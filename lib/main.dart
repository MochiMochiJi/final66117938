import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'helpers/database_helper.dart';
import 'constants/app_routes.dart';

import 'screens/home_screen.dart';
import 'screens/report_form_screen.dart';
import 'screens/incident_list_screen.dart';
import 'screens/search_filter_screen.dart';
import 'screens/edit_station_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Final66117938',
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.reportForm: (_) => const ReportFormScreen(),
        AppRoutes.incidentList: (_) => const IncidentListScreen(),
        AppRoutes.searchFilter: (_) => const SearchFilterScreen(),
        AppRoutes.editStationList: (_) => const EditStationListScreen(),
      },
    );
  }
}

