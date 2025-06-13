import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CrearMaquinariaPage extends StatefulWidget {
  const CrearMaquinariaPage({Key? key}) : super(key: key);

  @override
  _CrearMaquinariaPageState createState() => _CrearMaquinariaPageState();
}

class _CrearMaquinariaPageState extends State<CrearMaquinariaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool _isLoading = false;

  Future<void> _crearMaquinaria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final url = Uri.parse('http://152.228.216.84:8000/api/maquinaria/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': _nombreController.text,
          'descripcion': _descripcionController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maquinaria creada correctamente')),
        );
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body);
        _mostrarError(error.toString());
      }
    } catch (e) {
      _mostrarError('Error de conexión con el servidor.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva maquinaria')),
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
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _crearMaquinaria,
                child: const Text('Crear maquinaria'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
