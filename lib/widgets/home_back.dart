import 'package:flutter/material.dart';
import '../constants/app_routes.dart';

PreferredSizeWidget buildAppBarWithHome(String title, BuildContext context) {
  return AppBar(
    title: Text(title, overflow: TextOverflow.ellipsis),
    actions: [
      IconButton(
        icon: const Icon(Icons.home),
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        },
      ),
    ],
  );
}

