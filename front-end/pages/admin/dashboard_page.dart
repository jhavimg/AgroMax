import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'widgets/stat_card.dart';
import 'widgets/bar_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool cargando = true;
  bool acceso = false;

  Map<String, dynamic>? resumen;
  List<Map<String, dynamic>> tareasPorEstado = [];
  List<Map<String, dynamic>> tareasPorMes = [];
  List<Map<String, dynamic>> topTrabajadores = [];
  List<Map<String, dynamic>> topCuadrillas = [];
  List<Map<String, dynamic>> tareasPorTerreno = [];
  List<Map<String, dynamic>> maquinariaResumen = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      cargando = true;
      acceso = false;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    try {
      final endpoints = {
        'resumen': 'http://localhost:8000/api/dashboard/resumen/',
        'tareas_por_estado': 'http://localhost:8000/api/dashboard/tareas_por_estado/',
        'tareas_por_mes': 'http://localhost:8000/api/dashboard/tareas_por_mes/',
        'top_trabajadores': 'http://localhost:8000/api/dashboard/top_trabajadores/',
        'top_cuadrillas': 'http://localhost:8000/api/dashboard/top_cuadrillas/',
        'tareas_por_terreno': 'http://localhost:8000/api/dashboard/tareas_por_terreno/',
        'maquinaria_resumen': 'http://localhost:8000/api/dashboard/maquinaria_resumen/',
      };

      final responses = await Future.wait(endpoints.values.map((url) => http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'})));

      if (responses.every((res) => res.statusCode == 200)) {
        setState(() {
          resumen = jsonDecode(responses[0].body);
          tareasPorEstado = List<Map<String, dynamic>>.from(jsonDecode(responses[1].body));
          tareasPorMes = List<Map<String, dynamic>>.from(jsonDecode(responses[2].body));
          topTrabajadores = List<Map<String, dynamic>>.from(jsonDecode(responses[3].body));
          topCuadrillas = List<Map<String, dynamic>>.from(jsonDecode(responses[4].body));
          tareasPorTerreno = List<Map<String, dynamic>>.from(jsonDecode(responses[5].body));
          maquinariaResumen = List<Map<String, dynamic>>.from(jsonDecode(responses[6].body));
          cargando = false;
          acceso = true;
        });
      } else {
        setState(() {
          cargando = false;
          acceso = false;
        });
      }
    } catch (_) {
      setState(() {
        cargando = false;
        acceso = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 48),
      child: _buildDashboardContent(context),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!acceso) {
      return const Center(
        child: Text(
          'Acceso denegado. Solo para administradores.',
          style: TextStyle(fontSize: 20, color: Colors.redAccent),
        ),
      );
    }

    final statTerrenos = resumen?['num_terrenos'] ?? 0;
    final statTrabajadores = resumen?['num_trabajadores'] ?? 0;
    final statCuadrillas = resumen?['num_cuadrillas'] ?? 0;
    final statMaquinaria = resumen?['num_maquinaria'] ?? 0;
    final statTareas = resumen?['num_tareas'] ?? 0;
    final tareasPendientes = resumen?['tareas_pendientes'] ?? 0;
    final tareasCompletadas = resumen?['tareas_completadas'] ?? 0;
    final tareasNoCompletadas = resumen?['tareas_no_completadas'] ?? 0;

    final List<Map<String, dynamic>> tareasBarData = [
      {
        "estado": "Pendiente",
        "cantidad": tareasPendientes,
      },
      {
        "estado": "Completada",
        "cantidad": tareasCompletadas,
      },
      {
        "estado": "No completada",
        "cantidad": tareasNoCompletadas,
      },
    ];

    return ListView(
      children: [
        const Text(
          "Panel de estadísticas",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: Color(0xFF202124),
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 30),

        // KPIs
        SizedBox(
          height: 125,
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Terrenos',
                  value: '$statTerrenos',
                  icon: Icons.landscape,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  title: 'Trabajadores',
                  value: '$statTrabajadores',
                  icon: Icons.person,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  title: 'Cuadrillas',
                  value: '$statCuadrillas',
                  icon: Icons.groups,
                  color: Colors.orange[400]!,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  title: 'Maquinaria',
                  value: '$statMaquinaria',
                  icon: Icons.agriculture,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  title: 'Tareas',
                  value: '$statTareas',
                  icon: Icons.task,
                  color: Colors.purple[400]!,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // GRÁFICO DE TAREAS POR ESTADO
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tareas por estado",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 320,
                  child: SimpleBarChart(data: tareasBarData),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // GRÁFICO DE TAREAS POR MES
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tareas por mes",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 320,
                  child: SimpleBarChart(
                    data: tareasPorMes.map((e) => {
                      "estado": (e['mes'] ?? '').toString().substring(0, 7), // "2025-06"
                      "cantidad": e['total'] ?? 0,
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // TOP TRABAJADORES
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Top 5 Trabajadores (más tareas)",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                  },
                  border: TableBorder.all(color: Colors.grey.shade200),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFEFF7EE)),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Trabajador", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Tareas", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...topTrabajadores.map((t) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('${t['username'] ?? '-'}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('${t['num_tareas'] ?? 0}'),
                        ),
                      ],
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // TOP CUADRILLAS
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Top 5 Cuadrillas (más tareas)",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                  },
                  border: TableBorder.all(color: Colors.grey.shade200),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFEFF7EE)),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Cuadrilla", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Tareas", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...topCuadrillas.map((c) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('${c['nombre'] ?? '-'}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('${c['num_tareas'] ?? 0}'),
                        ),
                      ],
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // TAREAS POR TERRENO
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tareas por terreno",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                  },
                  border: TableBorder.all(color: Colors.grey.shade200),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFEFF7EE)),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Terreno", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Tareas", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...tareasPorTerreno.map((t) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('${t['nombre'] ?? '-'}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('${t['num_tareas'] ?? 0}'),
                        ),
                      ],
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // MAQUINARIA RESUMEN
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Maquinaria (tareas realizadas)",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                  },
                  border: TableBorder.all(color: Colors.grey.shade200),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFEFF7EE)),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Maquinaria", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Tareas", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...maquinariaResumen.map((m) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('${m['nombre'] ?? '-'}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('${m['num_tareas'] ?? 0}'),
                        ),
                      ],
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}
