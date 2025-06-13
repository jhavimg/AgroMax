import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EditarTareaPage extends StatefulWidget {
  final Map<String, dynamic> tarea;
  const EditarTareaPage({Key? key, required this.tarea}) : super(key: key);

  @override
  State<EditarTareaPage> createState() => _EditarTareaPageState();
}

class _EditarTareaPageState extends State<EditarTareaPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descripcionController;
  late TextEditingController _motivoNoCompletadoController;
  DateTime? _fechaSeleccionada;
  late String _estado;

  int? terrenoIdSeleccionado;
  List<int> trabajadoresSeleccionados = [];
  List<int> maquinasSeleccionadas = [];

  List<Map<String, dynamic>> terrenos = [];
  List<Map<String, dynamic>> trabajadores = [];
  List<Map<String, dynamic>> maquinas = [];

  List<Map<String, dynamic>> cuadrillas = [];
  List<int> cuadrillasSeleccionadas = [];

  @override
  void initState() {
    super.initState();
    final tarea = widget.tarea;
    _descripcionController = TextEditingController(text: tarea['descripcion'] ?? '');
    _motivoNoCompletadoController = TextEditingController(text: tarea['motivo_no_completado'] ?? '');
    _estado = tarea['estado'] ?? 'pendiente';
    _fechaSeleccionada = tarea['fecha_realizacion'] != null
        ? DateTime.tryParse(tarea['fecha_realizacion'])
        : null;

    // Preseleccionados
    terrenoIdSeleccionado = tarea['terreno']?['id'];
    trabajadoresSeleccionados = tarea['trabajadores'] != null
        ? List<int>.from(tarea['trabajadores'] as List)
        : [];
    maquinasSeleccionadas = tarea['maquinas'] != null
        ? List<int>.from((tarea['maquinas'] as List).map((m) => m['id']))
        : [];
    cuadrillasSeleccionadas = tarea['cuadrillas'] != null
        ? List<int>.from(tarea['cuadrillas'] as List)
        : [];

    _cargarTerrenos();
    _cargarTrabajadores();
    _cargarMaquinas();
    _cargarCuadrillas();
  }

  Future<void> _cargarTerrenos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/terrenos/');
    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          terrenos = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _cargarTrabajadores() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/users/workers/');
    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          trabajadores = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _cargarMaquinas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/maquinaria/');
    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          maquinas = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _cargarCuadrillas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/users/cuadrillas/');
    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          cuadrillas = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }


  Future<void> _guardarEdicion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha de realización.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/tareas/${widget.tarea['id']}/editar/');

    final body = {
      'descripcion': _descripcionController.text,
      'fecha_realizacion': "${_fechaSeleccionada!.year.toString().padLeft(4, '0')}-${_fechaSeleccionada!.month.toString().padLeft(2, '0')}-${_fechaSeleccionada!.day.toString().padLeft(2, '0')}",
      'estado': _estado,
      'motivo_no_completado': _motivoNoCompletadoController.text,
      'terreno': terrenoIdSeleccionado,
      "trabajadores": trabajadoresSeleccionados,     // <<-- ¡Solo individuales!
      "cuadrillas": cuadrillasSeleccionadas,         // <<-- ¡IDs de cuadrillas seleccionadas!
      'maquinas': maquinasSeleccionadas,
    };

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea actualizada')),
        );
        Navigator.pop(context, true); // true para recargar al volver
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar tarea: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión al servidor')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Tarea')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Descripción obligatoria' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_fechaSeleccionada == null
                      ? 'Selecciona fecha'
                      : 'Fecha: ${_fechaSeleccionada!.toLocal().toString().substring(0, 10)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaSeleccionada ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _fechaSeleccionada = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: terrenoIdSeleccionado,
                  items: terrenos
                      .map((t) => DropdownMenuItem<int>(
                      value: t['id'], child: Text(t['nombre'] ?? '')))
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Terreno'),
                  onChanged: (value) {
                    setState(() {
                      terrenoIdSeleccionado = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? 'Selecciona un terreno' : null,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Cuadrillas'),
                  child: Wrap(
                    children: cuadrillas
                        .map((c) => FilterChip(
                      label: Text(c['nombre']),
                      selected: cuadrillasSeleccionadas.contains(c['id']),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            cuadrillasSeleccionadas.add(c['id']);
                          } else {
                            cuadrillasSeleccionadas.remove(c['id']);
                          }
                        });
                      },
                    ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Trabajadores'),
                  child: Wrap(
                    children: trabajadores
                        .map((w) => ChoiceChip(
                      label: Text(w['username']),
                      selected: trabajadoresSeleccionados.contains(w['id']),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            trabajadoresSeleccionados.add(w['id']);
                          } else {
                            trabajadoresSeleccionados.remove(w['id']);
                          }
                        });
                      },
                    ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Máquinas'),
                  child: Wrap(
                    children: maquinas
                        .map((m) => ChoiceChip(
                      label: Text(m['nombre']),
                      selected: maquinasSeleccionadas.contains(m['id']),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            maquinasSeleccionadas.add(m['id']);
                          } else {
                            maquinasSeleccionadas.remove(m['id']);
                          }
                        });
                      },
                    ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: [
                    DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                    DropdownMenuItem(value: 'completada', child: Text('Completada')),
                    DropdownMenuItem(value: 'no_completada', child: Text('No completada')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estado = value!;
                    });
                  },
                  validator: (value) => value == null ? 'Selecciona el estado' : null,
                ),
                if (_estado == 'no_completada')
                  TextFormField(
                    controller: _motivoNoCompletadoController,
                    decoration: const InputDecoration(labelText: 'Motivo (si no está completada)'),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _guardarEdicion,
                  child: const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
