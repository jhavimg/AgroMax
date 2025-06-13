import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tfg/utils/weather_icons.dart';

class PrevisionPage extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  const PrevisionPage({required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final daily = weatherData['daily'];
    if (daily == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Previsión meteorológica")),
        body: Center(child: Text("No hay datos de previsión")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Previsión meteorológica"),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),
      backgroundColor: Colors.blue[50],
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: (daily['time'] as List).length,
        itemBuilder: (context, index) {
          final date = daily['time'][index];
          final maxT = daily['temperature_2m_max'][index];
          final minT = daily['temperature_2m_min'][index];
          final weathercode = daily['weathercode'][index];
          final icon = weatherCodeToIcon(weathercode)['icon'];
          final label = weatherCodeToIcon(weathercode)['label'];
          final prec = daily['precipitation_sum'][index];

          // Día de la semana y fecha bonita
          final DateTime dateObj = DateTime.parse(date);
          final dayName = DateFormat.E('es_ES').format(dateObj); // 'Lun', 'Mar', etc.
          final dayNum = DateFormat.d('es_ES').format(dateObj);
          final month = DateFormat.MMM('es_ES').format(dateObj);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  // Día grande a la izquierda
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dayName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue[800])),
                      Text(dayNum, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(month, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Icono del tiempo
                  Icon(icon, size: 40, color: Colors.orange[700]),
                  const SizedBox(width: 18),
                  // Datos principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _TempBar(minT: minT, maxT: maxT),
                            const SizedBox(width: 8),
                            Text(
                              "$maxT°C",
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                            Text(
                              " / $minT°C",
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.grain, size: 16, color: Colors.blue[600]),
                            const SizedBox(width: 4),
                            Text(
                              prec > 0 ? "$prec mm" : "Sin precip.",
                              style: TextStyle(
                                fontSize: 14,
                                color: prec > 0 ? Colors.blue[900] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Pequeño widget para una barra de temperatura moderna
class _TempBar extends StatelessWidget {
  final double minT, maxT;
  const _TempBar({required this.minT, required this.maxT});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.orange, Colors.red],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red[800],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
