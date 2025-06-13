import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'crear_tarea_page.dart';
import 'editar_tarea_page.dart';
import 'package:tfg/pages/detalle_tarea_page.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({Key? key}) : super(key: key);

  @override
  _TareasPageState createState() => _TareasPageState();
}

String mostrarEstado(String? estado) {
  switch (estado) {
    case 'completada':
      return 'Completada';
    case 'no_completada':
      return 'No completada';
    default:
      return 'Pendiente';
  }
}

class _TareasPageState extends State<TareasPage> {
  List<Map<String, dynamic>> tareas = [];
  List<Map<String, dynamic>> tareasFiltradas = [];
  final TextEditingController _buscadorController = TextEditingController();

  String userRole = 'ADMIN';
  int? userId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioYtareas();
  }

  Future<void> _cargarUsuarioYtareas() async {
    setState(() { loading = true; });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final urlUser = Uri.parse('http://152.228.216.84:8000/api/users/me/');

    try {
      final resUser = await http.get(
        urlUser,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (resUser.statusCode == 200) {
        final userJson = jsonDecode(resUser.body);
        userRole = userJson['role'] ?? 'ADMIN';
        userId = userJson['id'];
      }

      await _cargarTareas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el usuario')),
      );
    }
    setState(() { loading = false; });
  }

  Future<void> _cargarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/tareas/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        List<Map<String, dynamic>> tareasCargadas = List<Map<String, dynamic>>.from(data);

        // Filtra tareas por usuario si es WORKER
        if (userRole == "WORKER" && userId != null) {
          tareasCargadas = tareasCargadas.where((tarea) {
            bool asignada = false;
            // Directas
            if (tarea['trabajadores_detalle'] != null && tarea['trabajadores_detalle'] is List) {
              if ((tarea['trabajadores_detalle'] as List).any((w) => w['id'].toString() == userId.toString())) {
                asignada = true;
              }
            }
            // Cuadrillas
            if (!asignada && tarea['cuadrillas_detalle'] != null && tarea['cuadrillas_detalle'] is List) {
              for (var cuadrilla in tarea['cuadrillas_detalle']) {
                if (cuadrilla['trabajadores'] != null && cuadrilla['trabajadores'] is List) {
                  if ((cuadrilla['trabajadores'] as List).any((id) => id.toString() == userId.toString())) {
                    asignada = true;
                    break;
                  }
                }
              }
            }
            return asignada;
          }).toList();
        }

        setState(() {
          tareas = tareasCargadas;
          tareasFiltradas = tareas;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode}: No se pudieron cargar las tareas')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión al servidor')),
      );
    }
  }

  void _filtrarTareas(String query) {
    final filtradas = tareas.where((tarea) {
      final nombre = tarea['descripcion'].toString().toLowerCase();
      return nombre.contains(query.toLowerCase());
    }).toList();

    setState(() {
      tareasFiltradas = filtradas;
    });
  }

  Future<void> _eliminarTarea(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/tareas/$id/eliminar/');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada')),
        );
        _cargarTareas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tareas")),
      floatingActionButton: (userRole == "ADMIN")
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CrearTareaPage()),
          ).then((_) => _cargarTareas());
        },
        child: const Icon(Icons.add_task),
        tooltip: 'Nueva tarea',
      )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Listado de tareas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _buscadorController,
              decoration: const InputDecoration(
                hintText: 'Buscar por descripción',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filtrarTareas,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: tareasFiltradas.isEmpty
                  ? const Center(child: Text('No hay tareas disponibles'))
                  : ListView.builder(
                itemCount: tareasFiltradas.length,
                itemBuilder: (context, index) {
                  final t = tareasFiltradas[index];
                  return Card(
                    child: ListTile(
                      title: Text(t['descripcion'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha: ${t['fecha_realizacion'] ?? '-'}'),
                          Text('Estado: ${mostrarEstado(t['estado'])}'),
                          if (t['terreno_detalle'] != null)
                            Text('Terreno: ${t['terreno_detalle']['nombre'] ?? "-"}'),
                          if (t['trabajadores_detalle'] != null && t['trabajadores_detalle'] is List)
                            Text('Trabajadores: ${t['trabajadores_detalle'].map((w) => w['username']).join(", ")}'),
                          if (t['maquinas_detalle'] != null && t['maquinas_detalle'] is List)
                            Text('Máquinas: ${t['maquinas_detalle'].map((m) => m['nombre']).join(", ")}'),
                          if (t['motivo_no_completado'] != null && t['motivo_no_completado'] != "")
                            Text('Motivo: ${t['motivo_no_completado']}'),
                        ],
                      ),
                      trailing: (userRole == "ADMIN")
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditarTareaPage(tarea: t),
                                ),
                              ).then((_) => _cargarTareas());
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarTarea(t['id']),
                          ),
                        ],
                      )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetalleTareaPage(tareaId: t['id']),
                          ),
                        ).then((_) => _cargarTareas());
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
