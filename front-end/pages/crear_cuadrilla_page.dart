import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CrearCuadrillaPage extends StatefulWidget {
  const CrearCuadrillaPage({Key? key}) : super(key: key);

  @override
  State<CrearCuadrillaPage> createState() => _CrearCuadrillaPageState();
}

class _CrearCuadrillaPageState extends State<CrearCuadrillaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  List<dynamic> _trabajadores = [];
  List<int> _seleccionados = [];
  int? _responsable;

  bool _cargando = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarTrabajadores();
  }

  Future<void> _cargarTrabajadores() async {
    setState(() => _cargando = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/users/workers/');

    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _trabajadores = data;
          _cargando = false;
        });
      } else {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudieron cargar los trabajadores'))
        );
      }
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  Future<void> _crearCuadrilla() async {
    if (!_formKey.currentState!.validate() || _seleccionados.isEmpty) return;

    setState(() => _guardando = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final url = Uri.parse('http://152.228.216.84:8000/api/users/cuadrillas/');

    final body = {
      "nombre": _nombreController.text.trim(),
      "descripcion": _descController.text.trim(),
      "trabajadores": _seleccionados,
      "responsable": _responsable, // Puede ser null si no selecciona
    };

    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 201) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuadrilla creada correctamente')),
        );
      } else {
        final msg = res.body.isNotEmpty ? jsonDecode(res.body).toString() : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear cuadrilla: $msg')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión al guardar cuadrilla')),
      );
    }

    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear cuadrilla")),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la cuadrilla",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Obligatorio" : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Descripción (opcional)",
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 22),
              const Text("Selecciona trabajadores:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ..._trabajadores.map((trab) => CheckboxListTile(
                value: _seleccionados.contains(trab['id']),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _seleccionados.add(trab['id']);
                    } else {
                      _seleccionados.remove(trab['id']);
                      if (_responsable == trab['id']) {
                        _responsable = null;
                      }
                    }
                  });
                },
                title: Text(trab['username']),
                subtitle: Text('${trab['email']} - ${trab['telefono'] ?? ""}'),
              )),
              if (_seleccionados.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text("Responsable de la cuadrilla:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<int>(
                  value: _responsable,
                  hint: const Text("Selecciona responsable"),
                  items: _seleccionados
                      .map((id) {
                    final user = _trabajadores.firstWhere((t) => t['id'] == id);
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(user['username']),
                    );
                  })
                      .toList(),
                  onChanged: (val) => setState(() => _responsable = val),
                  validator: (v) =>
                  v == null ? "Selecciona responsable" : null,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_guardando ? "Guardando..." : "Crear cuadrilla"),
                onPressed: _guardando ? null : _crearCuadrilla,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
