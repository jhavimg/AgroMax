import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:tfg/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String email = '';
  String telefono = '';
  String role = '';
  bool isLoading = true;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token != null) {
      final url = Uri.parse('http://152.228.216.84:8000/api/users/me/');
      try {
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          setState(() {
            username = data['username'] ?? '';
            email = data['email'] ?? '';
            telefono = data['telefono'] ?? '';
            role = data['role'] ?? ''; // ¿Tu backend devuelve 'role'?
            _nombreController.text = username;
            _emailController.text = email;
            _telefonoController.text = telefono;
            _passwordController.clear();
            isLoading = false;
          });
        } else if (response.statusCode == 401) {
          // Token inválido: forzar logout
          await _logout();
        } else {
          _showError('Error al cargar los datos. Código: ${response.statusCode}');
        }
      } catch (e) {
        _showError('Error en la conexión.');
      }
    } else {
      await _logout();
    }
  }

  Future<void> _updateUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token != null) {
      final url = Uri.parse('http://152.228.216.84:8000/api/users/me/');
      try {
        final response = await http.patch(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'username': _nombreController.text,
            'email': _emailController.text,
            'telefono': _telefonoController.text,
            if (_passwordController.text.isNotEmpty)
              'password': _passwordController.text,
          }),
        );

        print('DEBUG: PATCH Status => ${response.statusCode}');
        print('DEBUG: PATCH Body => ${response.body}');

        if (response.statusCode == 200) {
          _showMessage('Datos actualizados correctamente.');
          await _loadUserData(); // Refresca datos tras editar
        } else if (response.statusCode == 400) {
          // Puede que el backend devuelva detalles en body
          final data = jsonDecode(response.body);
          _showError('Error: ${data.toString()}');
        } else {
          _showError('Error al actualizar los datos.');
        }
      } catch (e) {
        _showError('Error de conexión.');
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build (BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('Rol: $role'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateUserData,
                child: const Text('Guardar cambios'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _logout,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
