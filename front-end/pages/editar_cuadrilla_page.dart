import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class EditarCuadrillaPage extends StatefulWidget {
  final Map<String, dynamic> cuadrilla;
  const EditarCuadrillaPage({Key? key, required this.cuadrilla}) : super(key: key);

  @override
  State<EditarCuadrillaPage> createState() => _EditarCuadrillaPageState();
}

class _EditarCuadrillaPageState extends State<EditarCuadrillaPage> {
  late TextEditingController _nombreController;
  late TextEditingController _descController;
  List<Map<String, dynamic>> trabajadores = [];
  List<int> seleccionados = [];
  int? responsable;

  bool cargando = false;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cuadrilla['nombre']);
    _descController = TextEditingController(text: widget.cuadrilla['descripcion'] ?? "");
    seleccionados = List<int>.from(widget.cuadrilla['trabajadores'] ?? []);
    responsable = widget.cuadrilla['responsable'];
    _cargarTrabajadores();
  }

  Future<void> _cargarTrabajadores() async {
    setState(() => cargando = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/users/workers/');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          trabajadores = List<Map<String, dynamic>>.from(data);
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ${response.statusCode} al cargar trabajadores')));
      }
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error de conexión')));
    }
  }

  Future<void> _guardar() async {
    setState(() => guardando = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/users/cuadrillas/${widget.cuadrilla['id']}/');

    final body = jsonEncode({
      "nombre": _nombreController.text.trim(),
      "descripcion": _descController.text.trim(),
      "trabajadores": seleccionados,
      "responsable": responsable,
    });

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cuadrilla editada correctamente")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode} al editar cuadrilla")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error de conexión')));
    } finally {
      setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar cuadrilla")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(18.0),
        child: ListView(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre de la cuadrilla",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Selecciona los trabajadores:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              children: trabajadores
                  .map(
                    (t) => FilterChip(
                  label: Text(t['username']),
                  selected: seleccionados.contains(t['id']),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        seleccionados.add(t['id']);
                      } else {
                        seleccionados.remove(t['id']);
                        if (responsable == t['id']) responsable = null;
                      }
                    });
                  },
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              "Responsable:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<int>(
              value: responsable,
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Sin responsable'),
                ),
                ...trabajadores
                    .where((t) => seleccionados.contains(t['id']))
                    .map(
                      (t) => DropdownMenuItem<int>(
                    value: t['id'],
                    child: Text(t['username']),
                  ),
                )
                    .toList(),
              ],
              onChanged: (v) => setState(() => responsable = v),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Responsable",
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: guardando ? const CircularProgressIndicator() : const Text("Guardar cambios"),
              onPressed: guardando ? null : _guardar,
            ),
          ],
        ),
      ),
    );
  }
}
