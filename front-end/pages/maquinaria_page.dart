import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tfg/pages/crear_maquinaria_page.dart';
import 'package:tfg/pages/editar_maquinaria_page.dart';

class MaquinariaPage extends StatefulWidget {
  const MaquinariaPage({Key? key}) : super(key: key);

  @override
  _MaquinariaPageState createState() => _MaquinariaPageState();
}

class _MaquinariaPageState extends State<MaquinariaPage> {
  List<Map<String, dynamic>> maquinarias = [];
  List<Map<String, dynamic>> maquinariasFiltradas = [];
  final TextEditingController _buscadorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarMaquinarias();
  }

  void _cargarMaquinarias() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/maquinaria/');

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
          maquinarias = List<Map<String, dynamic>>.from(data);
          maquinariasFiltradas = maquinarias;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión al servidor')),
      );
    }
  }

  void _filtrarMaquinarias(String query) {
    final filtradas = maquinarias.where((m) {
      final nombre = m['nombre'].toLowerCase();
      return nombre.contains(query.toLowerCase());
    }).toList();

    setState(() {
      maquinariasFiltradas = filtradas;
    });
  }

  void _eliminarMaquinaria(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/maquinaria/$id/');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar maquinaria?'),
        content: const Text('Esta acción no se puede deshacer.'),
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
          const SnackBar(content: Text('Maquinaria eliminada')),
        );
        _cargarMaquinarias();
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
      appBar: AppBar(title: const Text("Maquinaria")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearMaquinariaPage()),
          ).then((_) => _cargarMaquinarias());
        },
        child: const Icon(Icons.add),
        tooltip: 'Nueva maquinaria',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Listado de maquinaria',
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
              onChanged: _filtrarMaquinarias,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: maquinariasFiltradas.length,
                itemBuilder: (context, index) {
                  final m = maquinariasFiltradas[index];
                  return Card(
                    child: ListTile(
                      title: Text(m['nombre']),
                      subtitle: Text(m['descripcion'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditarMaquinariaPage(maquinaria: m),
                                ),
                              ).then((_) => _cargarMaquinarias());
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarMaquinaria(m['id']),
                          ),
                        ],
                      ),
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