// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← AJOUTER

import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/admin/admin_login_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'core/models/admin_models.dart';
import 'core/models/escort_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null); // ← AJOUTER

  final session = SessionManager();
  await session.restaurer();

  runApp(
    ChangeNotifierProvider<SessionManager>.value(
      value: session,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _adminRoute = '/lecolis-admin-2025';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeColis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == _adminRoute) {
          return MaterialPageRoute(
            builder: (_) => AdminSession().estConnecte
                ? const AdminDashboardScreen()
                : const AdminLoginScreen(),
          );
        }
        if (settings.name == '/admin/dashboard') {
          return MaterialPageRoute(
            builder: (_) => AdminSession().estConnecte
                ? const AdminDashboardScreen()
                : const AdminLoginScreen(),
          );
        }
        return null;
      },
    );
  }
}