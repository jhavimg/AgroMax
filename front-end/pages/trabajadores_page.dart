import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tfg/pages/crear_trabajador_page.dart';
import 'package:tfg/pages/editar_trabajador_page.dart';
import 'package:tfg/pages/crear_cuadrilla_page.dart';
import 'package:tfg/pages/editar_cuadrilla_page.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnimatedSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const AnimatedSegmentedControl({
    Key? key,
    required this.selectedIndex,
    required this.onChanged,
    required this.labels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double height = 40;
    final double width = MediaQuery.of(context).size.width - 32;
    final double segmentWidth = width / labels.length;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green, width: 1.5),
      ),
      child: Stack(
        children: [
          // Botón deslizante animado
          AnimatedPositioned(
            duration: const Duration(milliseconds: 230),
            left: segmentWidth * selectedIndex,
            top: 0,
            bottom: 0,
            child: Container(
              width: segmentWidth,
              height: height,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Row(
            children: List.generate(labels.length, (i) {
              final bool selected = selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: Container(
                    height: height,
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.green[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class TrabajadoresPage extends StatefulWidget {
  const TrabajadoresPage({Key? key}) : super(key: key);

  @override
  _TrabajadoresPageState createState() => _TrabajadoresPageState();
}

class _TrabajadoresPageState extends State<TrabajadoresPage> {
  bool mostrarCuadrillas = false;
  int _selectedTab = 0; // 0 = trabajadores, 1 = cuadrillas

  // ---- TRABAJADORES ----
  List<Map<String, dynamic>> trabajadores = [];
  List<Map<String, dynamic>> trabajadoresFiltrados = [];
  final TextEditingController _buscadorController = TextEditingController();

  // ---- CUADRILLAS ----
  List<Map<String, dynamic>> cuadrillas = [];
  bool cargandoCuadrillas = false;

  @override
  void initState() {
    super.initState();
    _cargarTrabajadores();
    _cargarCuadrillas();
  }

  void _cargarTrabajadores() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final url = Uri.parse('http://152.228.216.84:8000/api/users/workers/');

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

        setState(() {
          trabajadores = List<Map<String, dynamic>>.from(data);
          trabajadoresFiltrados = trabajadores;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode}: No se pudieron cargar los trabajadores')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión al servidor')),
      );
    }
  }

  void _filtrarTrabajadores(String query) {
    final filtrados = trabajadores.where((trabajador) {
      final nombre = trabajador['username'].toLowerCase();
      return nombre.contains(query.toLowerCase());
    }).toList();

    setState(() {
      trabajadoresFiltrados = filtrados;
    });
  }

  void _eliminarTrabajador(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/users/$id/');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este trabajador?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')
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
          'Content-Type': 'applications/json',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trabajador eliminado')),
        );
        _cargarTrabajadores();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo eliminar'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  // ----- CUADRILLAS -----
  void _cargarCuadrillas() async {
    setState(() {
      cargandoCuadrillas = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/users/cuadrillas/'); // ¡Ajusta la URL según tu backend!

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

        setState(() {
          cuadrillas = List<Map<String, dynamic>>.from(data);
          cargandoCuadrillas = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode}: No se pudieron cargar las cuadrillas')),
        );
        setState(() {
          cargandoCuadrillas = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión al servidor')),
      );
      setState(() {
        cargandoCuadrillas = false;
      });
    }
  }

  void _eliminarCuadrilla(int cuadrillaId, String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/users/cuadrillas/$cuadrillaId/');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuadrilla'),
        content: Text('¿Seguro que quieres eliminar la cuadrilla "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
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
          SnackBar(content: Text('Cuadrilla "$nombre" eliminada')),
        );
        _cargarCuadrillas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo eliminar la cuadrilla'))
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
      appBar: AppBar(title: const Text("Trabajadores")),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearTrabajadorPage()),
          );
        },
        child: const Icon(Icons.person_add),
        tooltip: 'Nuevo trabajador',
      )
          : FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearCuadrillaPage()),
          );
        },
        child: const Icon(Icons.group_add),
        tooltip: 'Nueva cuadrilla',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // El selector moderno que te paso
            AnimatedSegmentedControl(
              selectedIndex: _selectedTab,
              onChanged: (index) {
                setState(() => _selectedTab = index);
              },
              labels: const ['Trabajadores', 'Cuadrillas'],
            ),
            const SizedBox(height: 22),
            if (_selectedTab == 0) ...[
              // --- VISTA TRABAJADORES (igual que antes) ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Listado de trabajadores',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _buscadorController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filtrarTrabajadores,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: trabajadoresFiltrados.length,
                  itemBuilder: (context, index) {
                    final t = trabajadoresFiltrados[index];
                    return Card(
                      child: ListTile(
                        title: Text(t['username']),
                        subtitle: Text('${t['email']} - ${t['telefono']}' ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarTrabajadorPage(trabajador: t),
                                  ),
                                ).then((_) => _cargarTrabajadores());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarTrabajador(t['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // --- VISTA CUADRILLAS ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Listado de cuadrillas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              // Aquí pon el ListView de cuadrillas, por ahora muestra placeholder:
              Expanded(
                child: cuadrillas.isEmpty
                    ? const Center(child: Text('No hay cuadrillas todavía.'))
                    : ListView.builder(
                  itemCount: cuadrillas.length,
                  itemBuilder: (context, index) {
                    final c = cuadrillas[index];
                    return Card(
                      child: ListTile(
                        title: Text(c['nombre']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((c['descripcion'] ?? '').isNotEmpty)
                              Text(c['descripcion']),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 18, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  c['responsable_detalle'] != null
                                      ? (c['responsable_detalle']['username'] ?? "Sin responsable")
                                      : "Sin responsable",
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "(Responsable)",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Editar cuadrilla',
                              onPressed: () async {
                                final actualizado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarCuadrillaPage(cuadrilla: c),
                                  ),
                                );
                                if (actualizado == true) _cargarCuadrillas();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar cuadrilla',
                              onPressed: () => _eliminarCuadrilla(c['id'], c['nombre']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrabajadoresView() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
              'Listado de trabajadores',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
              )
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _buscadorController,
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: _filtrarTrabajadores,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: trabajadoresFiltrados.length,
            itemBuilder: (context, index) {
              final t = trabajadoresFiltrados[index];
              return Card(
                child: ListTile(
                  title: Text(t['username']),
                  subtitle: Text('${t['email']} - ${t['telefono']}' ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarTrabajadorPage(trabajador: t),
                            ),
                          ).then((_) => _cargarTrabajadores());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarTrabajador(t['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCuadrillasView() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
              'Listado de cuadrillas',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
              )
          ),
        ),
        const SizedBox(height: 16),
        cargandoCuadrillas
            ? const Center(child: CircularProgressIndicator())
            : Expanded(
          child: cuadrillas.isEmpty
              ? const Center(child: Text("No hay cuadrillas registradas"))
              : ListView.builder(
            itemCount: cuadrillas.length,
            itemBuilder: (context, index) {
              final c = cuadrillas[index];
              return Card(
                child: ListTile(
                  title: Text(c['nombre']),
                  subtitle: Text(c['descripcion'] ?? ""),
                  // Aquí puedes añadir acciones de editar/eliminar cuadrilla en el futuro
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
