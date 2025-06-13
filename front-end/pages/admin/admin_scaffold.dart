import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({Key? key}) : super(key: key);

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    ProfilePage(),
    // UsersPage(), etc. (añade más páginas aquí)
  ];

  @override
  Widget build(BuildContext context) {
    final Color background = const Color(0xFFF6F5FB);

    return Scaffold(
      backgroundColor: background,
      body: Row(
        children: [
          // Sidebar
          _Sidebar(
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
          // Página seleccionada
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// SIDEBAR como widget separado
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _Sidebar({required this.selectedIndex, required this.onSelect, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Colors.green[700]!;

    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 0))],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOGO Y NOMBRE
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 0, 12),
              child: Row(
                children: [
                  Icon(Icons.agriculture, color: Colors.green[800], size: 34),
                  const SizedBox(width: 14),
                  const Text("AgroMax",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 23,
                        color: Color(0xFF202124),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // BOTÓN PERFIL (dos líneas)
            _SidebarButton(
              icon: Icons.account_circle_outlined,
              textLines: const ["Perfil", "administrador"],
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            // BOTÓN ESTADÍSTICAS
            _SidebarButton(
              icon: Icons.bar_chart,
              textLines: const ["Estadísticas"],
              selected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            // Puedes añadir más botones aquí:
            // _SidebarButton(...),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 22, bottom: 30, top: 12),
              child: Text(
                "© 2025 AgroMax",
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// BOTÓN REUTILIZABLE PARA EL MENÚ LATERAL
class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final List<String> textLines;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarButton({
    Key? key,
    required this.icon,
    required this.textLines,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Colors.green[700]!;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withOpacity(0.12) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? selectedColor : Colors.grey[700], size: 27),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: textLines
                  .map((line) => Text(
                line,
                style: TextStyle(
                  color: selected ? selectedColor : Colors.grey[800],
                  fontSize: 17,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  height: 1.1,
                ),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
