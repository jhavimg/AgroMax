import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CrearTareaPage extends StatefulWidget {
  @override
  State<CrearTareaPage> createState() => _CrearTareaPageState();
}

class _CrearTareaPageState extends State<CrearTareaPage> {
  int? terrenoSeleccionado;
  List<int> trabajadoresSeleccionados = [];
  List<int> maquinasSeleccionadas = [];
  String descripcion = "";
  DateTime? fechaRealizacion;
  bool estado = false; // false = pendiente, true = completada
  String motivoNoCompletado = "";

  List<Map<String, dynamic>> cuadrillas = [];
  List<int> cuadrillasSeleccionadas = [];

  List<Map<String, dynamic>> terrenos = [];
  List<Map<String, dynamic>> trabajadores = [];
  List<Map<String, dynamic>> maquinas = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('http://152.228.216.84:8000/api/terrenos/'), headers: headers),
        http.get(Uri.parse('http://152.228.216.84:8000/api/users/workers/'), headers: headers),
        http.get(Uri.parse('http://152.228.216.84:8000/api/maquinaria/'), headers: headers),
        http.get(Uri.parse('http://152.228.216.84:8000/api/users/cuadrillas/'), headers: headers),
      ]);
      if (responses.every((r) => r.statusCode == 200)) {
        setState(() {
          terrenos = List<Map<String, dynamic>>.from(jsonDecode(responses[0].body));
          trabajadores = List<Map<String, dynamic>>.from(jsonDecode(responses[1].body));
          maquinas = List<Map<String, dynamic>>.from(jsonDecode(responses[2].body));
          cuadrillas = List<Map<String, dynamic>>.from(jsonDecode(responses[3].body));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error cargando datos')));
    }
  }

  Future<void> _guardarTarea() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      "terreno": terrenoSeleccionado,
      "trabajadores": trabajadoresSeleccionados,    // <-- solo los individuales
      "cuadrillas": cuadrillasSeleccionadas,        // <-- los ids de cuadrillas
      "maquinas": maquinasSeleccionadas,
      "descripcion": descripcion,
      "fecha_realizacion": fechaRealizacion != null ? fechaRealizacion!.toIso8601String().split("T")[0] : null,
    });

    print("Enviando tarea: $body");

    try {
      final response = await http.post(
        Uri.parse('http://152.228.216.84:8000/api/tareas/'),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea creada correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creando tarea: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión al guardar tarea')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Tarea")),
      body: terrenos.isEmpty || trabajadores.isEmpty || maquinas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seleccionar terreno
                DropdownButtonFormField<int>(
                  value: terrenoSeleccionado,
                  items: terrenos.map<DropdownMenuItem<int>>((t) => DropdownMenuItem<int>(
                    value: t['id'],
                    child: Text(t['nombre']),
                  )).toList(),
                  onChanged: (v) => setState(() => terrenoSeleccionado = v),
                  decoration: const InputDecoration(labelText: "Terreno"),
                  validator: (v) => v == null ? "Selecciona un terreno" : null,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(labelText: "Cuadrillas"),
                  child: Wrap(
                    children: cuadrillas.map((cuadrilla) {
                      return FilterChip(
                        label: Text(cuadrilla['nombre']),
                        selected: cuadrillasSeleccionadas.contains(cuadrilla['id']),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              cuadrillasSeleccionadas.add(cuadrilla['id']);
                              // Puedes aquí marcar los trabajadores como seleccionados si quieres mostrarlo visualmente (opcional)
                            } else {
                              cuadrillasSeleccionadas.remove(cuadrilla['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Seleccionar trabajadores (multi)
                InputDecorator(
                  decoration: const InputDecoration(labelText: "Trabajadores"),
                  child: Wrap(
                    children: trabajadores.map((trabajador) {
                      return FilterChip(
                        label: Text(trabajador['username']),
                        selected: trabajadoresSeleccionados.contains(trabajador['id']),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              trabajadoresSeleccionados.add(trabajador['id']);
                            } else {
                              trabajadoresSeleccionados.remove(trabajador['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Seleccionar maquinas (multi)
                InputDecorator(
                  decoration: const InputDecoration(labelText: "Máquinas"),
                  child: Wrap(
                    children: maquinas.map((maquina) {
                      return FilterChip(
                        label: Text(maquina['nombre']),
                        selected: maquinasSeleccionadas.contains(maquina['id']),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              maquinasSeleccionadas.add(maquina['id']);
                            } else {
                              maquinasSeleccionadas.remove(maquina['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  decoration: const InputDecoration(labelText: "Descripción"),
                  onChanged: (v) => descripcion = v,
                  validator: (v) => v == null || v.isEmpty ? "Introduce una descripción" : null,
                ),
                const SizedBox(height: 16),

                // Fecha de realización
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Fecha de realización: ${fechaRealizacion != null ? "${fechaRealizacion!.day}/${fechaRealizacion!.month}/${fechaRealizacion!.year}" : "Selecciona una fecha"}"),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaRealizacion ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => fechaRealizacion = picked);
                  },
                ),
                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: _guardarTarea,
                    icon: const Icon(Icons.save),
                    label: const Text("Guardar tarea"),
                  ),
                ),
              ],
            )
        ),
      ),
    );
  }
}
