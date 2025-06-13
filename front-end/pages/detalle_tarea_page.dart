import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:tfg/pages/ver_terreno_trabajador_page.dart';
import 'package:tfg/pages/home_page.dart';

class DetalleTareaPage extends StatefulWidget {
  final int tareaId;

  const DetalleTareaPage({Key? key, required this.tareaId}) : super(key: key);

  @override
  State<DetalleTareaPage> createState() => _DetalleTareaPageState();
}

class _DetalleTareaPageState extends State<DetalleTareaPage> {
  Map<String, dynamic>? tarea;
  bool cargando = true;
  String userRole = "WORKER"; // Por defecto

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Carga el rol del usuario desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('userRole') ?? "WORKER";
    });
    await _cargarDetalle();
  }

  Future<Map<String, dynamic>> fetchTerrenoDetalle(int terrenoId) async {
    final res = await http.get(Uri.parse('http://152.228.216.84:8000/api/terrenos/$terrenoId/'));
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception("No se pudo cargar el terreno");
    }
  }

  Future<void> _cargarDetalle() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/tareas/${widget.tareaId}/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          tarea = jsonDecode(utf8.decode(response.bodyBytes));
          cargando = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar detalle')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  Future<void> _marcarComoCompletada(bool completada, [String? motivo]) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final url = Uri.parse('http://152.228.216.84:8000/api/tareas/${widget.tareaId}/editar/');

    Map<String, dynamic> body = {
      "estado": completada ? "completada" : "no_completada",
      "motivo_no_completada": completada ? "" : (motivo ?? ''),
    };

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
          SnackBar(content: Text('Actualizado correctamente')),
        );
        _cargarDetalle();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando estado')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  void _dialogMotivoNoCompletada() {
    final motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Razón de no completada"),
        content: TextField(
          controller: motivoController,
          decoration: InputDecoration(hintText: "Describe la razón"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _marcarComoCompletada(false, motivoController.text);
            },
            child: Text("Enviar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return Scaffold(body: Center(child: CircularProgressIndicator()));

    if (tarea == null) return Scaffold(body: Center(child: Text("No se encontró la tarea")));

    return Scaffold(
      appBar: AppBar(title: Text("Detalle de la tarea")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text("Descripción:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(tarea!['descripcion'] ?? "-"),
            SizedBox(height: 10),
            Text("Fecha:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(tarea!['fecha_realizacion'] ?? "-"),
            SizedBox(height: 10),
            Text("Estado:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              tarea!['estado'] == "no_completada"
                  ? "No completada"
                  : (tarea!['estado'] ?? "-"),
            ),
            SizedBox(height: 10),
            if (tarea!['terreno_detalle'] != null) ...[
              Row(
                children: [
                  Text("Terreno:", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Text(tarea!['terreno_detalle']['nombre'] ?? "-"),
                  Spacer(),
                  ElevatedButton.icon(
                    icon: Icon(Icons.map),
                    label: Text("Ver terreno"),
                    onPressed: () async {
                      final terrenoId = tarea!['terreno_detalle']['id'];
                      if (userRole == 'ADMIN') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage(userRole: userRole, initialTerrenoId: terrenoId),
                          ),
                        );
                      } else {
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => Center(child: CircularProgressIndicator()),
                          );
                          final terrenoDetalle = await fetchTerrenoDetalle(terrenoId);
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TerrenoMeteoTrabajadorPage(terrenoDetalle: terrenoDetalle),
                            ),
                          );
                        } catch (e) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error cargando terreno: $e")),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
            Text("Trabajadores:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(tarea!['trabajadores_detalle']
                ?.map((w) => w['username'])
                ?.join(", ") ??
                "-"),
            SizedBox(height: 10),
            if ((tarea!['cuadrillas_detalle'] ?? []).isNotEmpty) ...[
              Text("Cuadrillas:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...tarea!['cuadrillas_detalle'].map<Widget>((cuadrilla) {
                final miembros = (cuadrilla['trabajadores_detalle'] as List?)
                    ?.map((w) => w['username'])
                    ?.join(", ") ?? "-";
                final responsable = cuadrilla['responsable_detalle']?['username'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• ${cuadrilla['nombre']}${responsable != null ? " (Resp: $responsable)" : ""}", style: TextStyle(fontWeight: FontWeight.w600)),
                      Text("  Miembros: $miembros", style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 10),
            ],
            Text("Máquinas:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(tarea!['maquinas_detalle']
                ?.map((m) => m['nombre'])
                ?.join(", ") ??
                "-"),
            SizedBox(height: 10),
            if ((tarea!['motivo_no_completada'] ?? '').isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Motivo de no completada:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(tarea!['motivo_no_completada']),
                ],
              ),
            SizedBox(height: 40),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (tarea!['estado'] != "completada")
                  ElevatedButton.icon(
                    icon: Icon(Icons.check_circle, color: Colors.green),
                    label: Text("Marcar como completada"),
                    onPressed: () => _marcarComoCompletada(true),
                  ),
                ElevatedButton.icon(
                  icon: Icon(Icons.cancel, color: Colors.red),
                  label: Text("No completada"),
                  onPressed: _dialogMotivoNoCompletada,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
