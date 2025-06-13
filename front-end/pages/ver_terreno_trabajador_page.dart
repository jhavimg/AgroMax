import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:tfg/pages/prevision_meteorologica_page.dart';

class TerrenoMeteoTrabajadorPage extends StatefulWidget {
  final Map<String, dynamic> terrenoDetalle;

  const TerrenoMeteoTrabajadorPage({Key? key, required this.terrenoDetalle}) : super(key: key);

  @override
  State<TerrenoMeteoTrabajadorPage> createState() => _TerrenoMeteoTrabajadorPageState();
}

class _TerrenoMeteoTrabajadorPageState extends State<TerrenoMeteoTrabajadorPage> {
  Map<String, dynamic>? meteo;
  bool cargando = true;
  bool mapaCargando = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    cargarMeteo();
  }

  Future<void> cargarMeteo() async {
    setState(() { cargando = true; });
    try {
      final terrenoId = widget.terrenoDetalle['id'];
      final url = Uri.parse('http://152.228.216.84:8000/api/terrenos/$terrenoId/meteo/');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          meteo = json.decode(res.body);
        });
      }
    } catch (_) {}
    setState(() { cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    List puntos = widget.terrenoDetalle['puntos'] ?? [];
    List<LatLng> polygon = [];
    if (puntos.isNotEmpty && puntos.length >= 3) {
      polygon = (puntos as List).map<LatLng>((p) => LatLng(p[0], p[1])).toList();
    }
    // Calcular centroide
    LatLng? centroide;
    if (polygon.isNotEmpty) {
      double lat = 0, lon = 0;
      for (var p in polygon) {
        lat += p.latitude;
        lon += p.longitude;
      }
      centroide = LatLng(lat / polygon.length, lon / polygon.length);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Terreno y Previsión"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Text(
                "Terreno: ${widget.terrenoDetalle['nombre'] ?? '-'}",
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
            // --- MAPA ---
            if (polygon.isEmpty || polygon.length < 3)
              const Expanded(
                child: Center(child: Text("Este terreno no tiene área geográfica definida.")),
              )
            else
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: centroide!,
                        zoom: 16,
                      ),
                      polygons: {
                        Polygon(
                          polygonId: PolygonId("terreno"),
                          points: polygon,
                          fillColor: Colors.orange.withOpacity(0.32),
                          strokeColor: Colors.orange,
                          strokeWidth: 2,
                        )
                      },
                      markers: {
                        Marker(
                          markerId: MarkerId("terreno_centro"),
                          position: centroide!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                        ),
                      },
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      mapType: MapType.satellite,
                      onMapCreated: (controller) {
                        setState(() => mapaCargando = false);
                        _mapController = controller;
                      },
                    ),
                    if (mapaCargando)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            // --- INFORMACIÓN DEL TIEMPO Y BOTÓN DE PREVISIÓN ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 14),
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : (meteo == null)
                  ? const Text("No se pudo obtener la previsión meteorológica")
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meteo!['current_weather'] != null) ...[
                    Text("Ahora:", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Icon(Icons.thermostat, color: Colors.red),
                        Text(" ${meteo!['current_weather']['temperature']}°C"),
                        const SizedBox(width: 14),
                        Icon(Icons.air, color: Colors.blue),
                        Text(" ${meteo!['current_weather']['windspeed']} km/h"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.calendar_today),
                      label: Text('Ver previsión 7 días'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrevisionPage(weatherData: meteo!),
                          ),
                        );
                      },
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
