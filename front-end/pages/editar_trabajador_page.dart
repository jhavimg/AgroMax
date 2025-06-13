import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EditarTrabajadorPage extends StatefulWidget {
  final Map<String, dynamic> trabajador;

  const EditarTrabajadorPage({Key? key, required this.trabajador}) : super(key: key);

  @override
  _EditarTrabajadorPageState createState() => _EditarTrabajadorPageState();
}

class _EditarTrabajadorPageState extends State<EditarTrabajadorPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.trabajador['username']);
    _emailController = TextEditingController(text: widget.trabajador['email']);
    _telefonoController = TextEditingController(text: widget.trabajador['telefono'] ?? '');
  }

  Future<void> _actualizarTrabajador() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final id = widget.trabajador['id'];

    final url = Uri.parse('http://152.228.216.84:8000/api/users/$id/');

    final body = {
      'username': _nombreController.text,
      'email': _emailController.text,
      'telefono': _telefonoController.text,
    };

    if (_passwordController.text.isNotEmpty) {
      body['password'] = _passwordController.text;
    }

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trabajador actualizado')),
        );
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        final mensaje = errorData.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join('\n');
        _showError(mensaje);
      }
    } catch (e) {
      _showError('Error de conexión al servidor.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showError(String mensaje){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar trabajador')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Nombre requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) =>
                value == null || !value.contains('@') ? 'Email inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) =>
                value == null || value.length < 9 ? 'Teléfono inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña (opcional)'),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _actualizarTrabajador,
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}