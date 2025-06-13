import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:tfg/pages/terrenos_page.dart';
import 'package:tfg/pages/trabajadores_page.dart';
import 'package:tfg/pages/tareas_page.dart';
import 'package:tfg/pages/maquinaria_page.dart';
import 'package:tfg/pages/profile_page.dart';
import 'package:tfg/pages/crear_tarea_page.dart';

class HomePage extends StatefulWidget {
  final String userRole;  // ADMIN o WORKER
  final int? initialTerrenoId;

  const HomePage({
    Key? key,
    required this.userRole,
    this.initialTerrenoId,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;
  int? userId;

  @override
  void initState() {
    super.initState();

    // Si viene un terrenoId, abre la pestaña de terrenos
    if (widget.userRole == 'ADMIN' && widget.initialTerrenoId != null) {
      _selectedIndex = 1; // 0=Inicio, 1=Terrenos...
    }

    _pages = _buildPages();
    _navItems = _buildNavItems();
  }

  List<Widget> _buildPages() {
    if (widget.userRole == 'ADMIN') {
      return [
        InicioPage(userRole: widget.userRole),
        TerrenosPage(
          initialTerrenoId: widget.initialTerrenoId,
        ),
        TrabajadoresPage(),
        TareasPage(),
        MaquinariaPage(),
      ];
    } else {
      return [
        InicioPage(userRole: widget.userRole),
        TareasPage(),
      ];
    }
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    if (widget.userRole == 'ADMIN') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Terrenos'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Trabajadores'),
        BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tareas'),
        BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Maquinaria'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Mis tareas'),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _pages = _buildPages();  // Vuelve a calcular por si acaso cambia el rol en hot reload
    _navItems = _buildNavItems();
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        toolbarHeight: 80,
        centerTitle: true,
        leading: const SizedBox(width: 48),
        title: Container(
          alignment: Alignment.center,
          child: Image.asset(
            'assets/Logo_AgroMax.png',
            height: 60,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}

class InicioPage extends StatefulWidget {
  final String userRole;
  const InicioPage({Key? key, required this.userRole}) : super(key: key);

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  String userName = '';
  int? userId;
  int terrenos = 0, tareas = 0, maquinaria = 0, trabajadores = 0;

  bool loading = true;
  Map<DateTime, List<dynamic>> tareasPorDia = {};
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  bool loadingTareas = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await _fetchDashboardData();
  }

  bool contieneId(dynamic lista, dynamic id) {
    if (lista == null || id == null) return false;
    try {
      return (lista as List).any((element) =>
      element.toString() == id.toString());
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() { loading = true; });

    try {
      // Obtener usuario actual y nombre
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final resUser = await http.get(
        Uri.parse('http://152.228.216.84:8000/api/users/me/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final userJson = jsonDecode(resUser.body);
      userName = userJson['username'] ?? 'Usuario';
      userId = userJson['id'];

      // Aquí solo llamas a fetchTareas después de cargar userId
      await _fetchTareasCalendario();

      if (widget.userRole == "ADMIN") {
        // Resumen rápido (solo para admin)
        final resTerrenos = await http.get(Uri.parse('http://152.228.216.84:8000/api/terrenos/'));
        final resTareas = await http.get(Uri.parse('http://152.228.216.84:8000/api/tareas/'));
        final resMaquinaria = await http.get(
          Uri.parse('http://152.228.216.84:8000/api/maquinaria/'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final resTrabajadores = await http.get(
          Uri.parse('http://152.228.216.84:8000/api/users/workers/'),
          headers: {'Authorization': 'Bearer $token'},
        );

        final terrenosList = jsonDecode(resTerrenos.body) as List;
        terrenos = terrenosList.length;
        tareas = (jsonDecode(resTareas.body) as List).length;
        maquinaria = (jsonDecode(resMaquinaria.body) as List).length;
        if (resTrabajadores.statusCode == 200) {
          trabajadores = (jsonDecode(resTrabajadores.body) as List).length;
        } else {
          trabajadores = 0;
        }
      }

      setState(() { loading = false; });
    } catch (e) {
      setState(() { loading = false; });
    }
  }

  Future<void> _fetchTareasCalendario() async {
    setState(() => loadingTareas = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final res = await http.get(
        Uri.parse('http://152.228.216.84:8000/api/tareas/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        Map<DateTime, List<dynamic>> tareasMap = {};

        for (var tarea in data) {
          bool asignada = false;
          if (widget.userRole == "WORKER" && userId != null) {
            // Asignación directa
            if (tarea['trabajadores_detalle'] != null && tarea['trabajadores_detalle'] is List) {
              if ((tarea['trabajadores_detalle'] as List).any((w) => w['id'].toString() == userId.toString())) {
                asignada = true;
              }
            }
            // Por cuadrilla
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
          } else if (widget.userRole == "ADMIN") {
            asignada = true;
          }

          if (!asignada) continue;

          final fechaStr = tarea['fecha_realizacion'];
          if (fechaStr != null && fechaStr.isNotEmpty) {
            DateTime fecha = DateTime.parse(fechaStr);
            final fechaKey = DateTime.utc(fecha.year, fecha.month, fecha.day);
            tareasMap[fechaKey] = tareasMap[fechaKey] ?? [];
            tareasMap[fechaKey]!.add(tarea);
          }
        }
        print('Tareas finales por día para este trabajador: $tareasMap');
        setState(() {
          tareasPorDia = tareasMap;
        });
      }
    } catch (e) {
      print('ERROR AL FILTRAR TAREAS: $e');
    }
    setState(() => loadingTareas = false);
  }


  List<dynamic> _tareasDelDia(DateTime day) {
    final dayKey = DateTime.utc(day.year, day.month, day.day);
    return tareasPorDia[dayKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userRole == "WORKER") {
      // VISTA PARA TRABAJADORES
      return loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida personalizada
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.agriculture, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '¡Hola, $userName!',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Bienvenido a tu panel de control agrícola.",
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 28),
            const Text(
              "Calendario de tareas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  eventLoader: _tareasDelDia,
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      focusedDay = focused;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.green[200],
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            loadingTareas
                ? const Center(child: CircularProgressIndicator())
                : _buildListaTareasDelDia(),
          ],
        ),
      );
    }
    // VISTA PARA ADMIN (igual que antes)
    return loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenida personalizada
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.green,
                child: Icon(Icons.agriculture, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '¡Hola, $userName!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Bienvenido a tu panel de control agrícola.",
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(height: 20),
          // Resumen rápido
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResumenItem(icon: Icons.landscape, label: "Terrenos", count: terrenos),
                  _ResumenItem(icon: Icons.task, label: "Tareas", count: tareas),
                  _ResumenItem(icon: Icons.agriculture, label: "Maquinaria", count: maquinaria),
                  _ResumenItem(icon: Icons.group, label: "Trabajadores", count: trabajadores),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Botón acceso rápido a Nueva Tarea
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_task),
                label: const Text("Crear nueva tarea"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                  textStyle: const TextStyle(fontSize: 18),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CrearTareaPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            "Calendario de tareas",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                calendarFormat: CalendarFormat.month,
                eventLoader: _tareasDelDia,
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.green[200],
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          loadingTareas
              ? const Center(child: CircularProgressIndicator())
              : _buildListaTareasDelDia(),
        ],
      ),
    );
  }

  Widget _buildListaTareasDelDia() {
    final hoy = selectedDay ?? DateTime.now();
    final tareas = _tareasDelDia(hoy);

    if (tareas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No hay tareas programadas para este día."),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tareas.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final tarea = tareas[idx];
          return ListTile(
            leading: Icon(Icons.task_alt, color: Colors.green[700]),
            title: Text(tarea['descripcion'] ?? "Sin título"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Terreno: ${tarea['terreno_detalle']?['nombre'] ?? ''}"),
                  Text("Estado: ${tarea['estado']}"),
                ],
              ),
          );
        },
      ),
    );
  }

}

// Widget auxiliar para los contadores rápidos (solo para admin)
class _ResumenItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _ResumenItem({required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(icon, color: Colors.green[700], size: 28),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        )
      ],
    );
  }
}
