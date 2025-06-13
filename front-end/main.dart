import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tfg/pages/login_page.dart';
import 'package:tfg/pages/home_page.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter/foundation.dart';
import 'package:tfg/pages/admin/admin_scaffold.dart';

import 'package:tfg/pages/terrenos_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('authToken'); // ⚠️ SOLO para pruebas
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final role = prefs.getString('userRole') ?? 'WORKER';
    return {
      'isLoggedIn': token != null,
      'role': role,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroMax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final userRole = args['userRole'] ?? 'WORKER';
          final terrenoId = args['terrenoId'] as int?;
          return MaterialPageRoute(
            builder: (_) =>
                HomePage(userRole: userRole, initialTerrenoId: terrenoId),
          );
        }
        // Ruta por defecto (pantalla de login con check de token)
        return MaterialPageRoute(
          builder: (context) =>
              FutureBuilder<Map<String, dynamic>>(
                future: _getUserData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    final data = snapshot.data!;
                    if (data['isLoggedIn']) {
                      // 🚩 REDIRECCIÓN AL DASHBOARD SOLO SI WEB Y ADMIN
                      if (kIsWeb && data['role'] == 'ADMIN') {
                        return AdminScaffold();
                      } else {
                        return HomePage(userRole: data['role']);
                      }
                    } else {
                      return const LoginPage();
                    }
                  }
                },
              ),
        );
      },
      // home: ya no hace falta si tienes onGenerateRoute
    );
  }
}