import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:tfg/utils/weather_icons.dart';
import 'package:tfg/pages/prevision_meteorologica_page.dart';

class Terreno {
  final int id;
  final String nombre;
  final String descripcion;
  final List<LatLng> puntos;
  final double area;

  Terreno({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.puntos,
    required this.area,
  });

  factory Terreno.fromJson(Map<String, dynamic> json) {
    return Terreno(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      area: (json['area'] as num).toDouble(),
      puntos: (json['puntos'] as List)
          .map<LatLng>((p) => LatLng(p[0], p[1]))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "descripcion": descripcion,
      "puntos": puntos.map((p) => [p.latitude, p.longitude]).toList(),
    };
  }
}

class TerrenosPage extends StatefulWidget {
  final int? initialTerrenoId;

  const TerrenosPage({
    Key? key,
    this.initialTerrenoId,
  }) : super(key: key);

  @override
  State<TerrenosPage> createState() => _TerrenosPageState();
}

class _TerrenosPageState extends State<TerrenosPage> {
  late GoogleMapController mapController;
  LatLng? currentPosition;

  List<Terreno> terrenosGuardados = [];
  Set<Polygon> polygons = {};
  Set<Marker> terrainMarkers = {};
  List<LatLng> puntosTerreno = [];
  bool modoDibujo = false;
  bool mostrarListaTerrenos = false;
  Set<Polygon> polygonsSIGPAC = {};
  bool mostrandoSIGPAC = false;

  bool _argumentoProcesado = false;
  bool _mapReady = false;
  int? _pendingTerrenoId;

  Map<String, dynamic>? _weatherData;
  bool _weatherLoading = false;

  final String backendUrl = "http://152.228.216.84:8000/api/terrenos/";

  int? terrenoSeleccionadoIndex;
  Terreno? get terrenoSeleccionado =>
      terrenoSeleccionadoIndex != null && terrenoSeleccionadoIndex! >= 0 && terrenoSeleccionadoIndex! < terrenosGuardados.length
          ? terrenosGuardados[terrenoSeleccionadoIndex!]
          : null;


  @override
  void initState() {
    super.initState();
    _detectarUbicacion();
    _refrescarTerrenos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  LatLng _calcularCentroide(List<LatLng> puntos) {
    double lat = 0;
    double lng = 0;
    for (var punto in puntos) {
      lat += punto.latitude;
      lng += punto.longitude;
    }
    return LatLng(lat / puntos.length, lng / puntos.length);
  }

  /// Llama a este método siempre que terminen de cargar los terrenos o el mapa.
  /// Si no puede seleccionar el terreno aún, lo intentará de nuevo más tarde.
  void _intentarSeleccionarTerrenoInicial() {
    if (_argumentoProcesado) return;
    final terrenoId = widget.initialTerrenoId;
    if (!_mapReady || terrenosGuardados.isEmpty || terrenoId == null) {
      // No está todo listo, lo intentamos luego
      _pendingTerrenoId = terrenoId;
      return;
    }

    final idx = terrenosGuardados.indexWhere((t) => t.id == terrenoId);
    if (idx != -1) {
      setState(() {
        terrenoSeleccionadoIndex = idx;
        _argumentoProcesado = true;
      });
      final centro = _calcularCentroide(terrenosGuardados[idx].puntos);
      mapController.animateCamera(CameraUpdate.newLatLngZoom(centro, 17.0));
    }
    _pendingTerrenoId = null;
  }

  Future<void> _refrescarTerrenos() async {
    try {
      final terrenos = await fetchTerrenos();
      setState(() {
        terrenosGuardados = terrenos;
        polygons = terrenos.map((terreno) {
          return Polygon(
            polygonId: PolygonId('terreno_${terreno.id}'),
            points: terreno.puntos,
            strokeColor: Colors.red,
            fillColor: Colors.red.withOpacity(0.3),
            strokeWidth: 2,
          );
        }).toSet();
        terrainMarkers = terrenos.map((terreno) {
          final centro = _calcularCentroide(terreno.puntos);
          return Marker(
            markerId: MarkerId('terreno_${terreno.id}'),
            position: centro,
            infoWindow: InfoWindow(title: terreno.nombre),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          );
        }).toSet();
      });

      _intentarSeleccionarTerrenoInicial();

    } catch (e) {
      print("Error refrescando terrenos: $e");
    }
  }

  // --- Métodos de backend ---
  Future<List<Terreno>> fetchTerrenos() async {
    final res = await http.get(Uri.parse(backendUrl));
    if (res.statusCode == 200) {
      final List data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((json) => Terreno.fromJson(json)).toList();
    } else {
      throw Exception("Error al cargar terrenos");
    }
  }

  Future<void> crearTerreno(Terreno terreno) async {
    final res = await http.post(
      Uri.parse('$backendUrl'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(terreno.toJson()),
    );
    if (res.statusCode != 201) throw Exception("Error al crear terreno");
  }

  Future<void> eliminarTerreno(int id) async {
    final res = await http.delete(Uri.parse('http://152.228.216.84:8000/api/terrenos/$id/eliminar/'));
    if (res.statusCode != 204) throw Exception("Error al eliminar terreno");
  }

  Future<void> editarTerreno(int id, String nuevoNombre, String nuevaDesc) async {
    final res = await http.patch(
      Uri.parse('http://152.228.216.84:8000/api/terrenos/$id/editar/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"nombre": nuevoNombre, "descripcion": nuevaDesc}),
    );
    if (res.statusCode != 200) throw Exception("Error al editar terreno");
  }
  // --- FIN backend ---

  Future<void> _detectarUbicacion() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = LatLng(pos.latitude, pos.longitude);
      });
    }
  }

  void _guardarTerreno() async {
    if (puntosTerreno.length < 3) return;
    final result = await _mostrarDialogoNombreDescripcion();
    if (result == null) return;
    final nombre = result['nombre']!;
    final descripcion = result['descripcion']!;
    final nuevoTerreno = Terreno(
      id: 0, // lo pone el backend
      nombre: nombre,
      descripcion: descripcion,
      puntos: List.from(puntosTerreno),
      area: 0,
    );
    try {
      await crearTerreno(nuevoTerreno);
      puntosTerreno.clear();
      modoDibujo = false;
      await _refrescarTerrenos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terreno "$nombre" guardado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error guardando terreno: $e")),
      );
    }
    setState(() {});
  }

  Future<Map<String, String>?> _mostrarDialogoNombreDescripcion({String? nombre, String? descripcion}) async {
    String nombreValue = nombre ?? "";
    String descValue = descripcion ?? "";
    final nombreController = TextEditingController(text: nombreValue);
    final descController = TextEditingController(text: descValue);
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Detalles del terreno"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: "Nombre (Ej. Terreno norte)"),
              controller: nombreController,
            ),
            TextField(
              decoration: const InputDecoration(hintText: "Descripción"),
              controller: descController,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
              onPressed: () {
                if (nombreController.text.trim().isEmpty) return;
                Navigator.pop(context, {
                  "nombre": nombreController.text,
                  "descripcion": descController.text,
                });
              },
              child: const Text("Guardar")),
        ],
      ),
    );
  }

  void _activarModoDibujo() {
    setState(() {
      modoDibujo = true;
      puntosTerreno.clear();
    });
    Navigator.pop(context); // Cierra el bottom sheet
  }

  void _procesarSeleccionInicial() {
    // Procesa sólo si está todo listo y no se ha hecho ya
    if (_argumentoProcesado) return;
    if (!_mapReady) return;
    if (terrenosGuardados.isEmpty) return;
    if (widget.initialTerrenoId == null) return;

    final idx = terrenosGuardados.indexWhere((t) => t.id == widget.initialTerrenoId);
    if (idx != -1) {
      setState(() {
        terrenoSeleccionadoIndex = idx;
      });
      final centro = _calcularCentroide(terrenosGuardados[idx].puntos);
      mapController.animateCamera(CameraUpdate.newLatLngZoom(centro, 17.0));
    }
    _argumentoProcesado = true;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _mapReady = true;
    _intentarSeleccionarTerrenoInicial();
  }

  void _onAnadirTerrenoPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Container(
          margin: const EdgeInsets.only(bottom: 60, top: 30),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_location_alt),
                title: const Text("Dibujar área en el mapa"),
                onTap: _activarModoDibujo,
              ),
              ListTile(
                leading: const Icon(Icons.layers),
                title: const Text("Importar recintos agrícolas visibles"),
                onTap: () => _importarDesdeSIGPAC(cerrarSheet: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmarCancelarDibujo() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancelar dibujo del terreno"),
        content: const Text("¿Estás seguro de que quieres cancelar? Se perderán los puntos marcados."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Seguir dibujando")),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Cancelar dibujo")),
        ],
      ),
    ) ?? false;
  }

  Future<LatLngBounds?> _getVisibleRegion() async {
    try {
      return await mapController.getVisibleRegion();
    } catch (e) {
      print("Error obteniendo región visible: $e");
      return null;
    }
  }

  void _mostrarRecintosSIGPAC(List<dynamic> data) {
    setState(() {
      polygonsSIGPAC = data.map((recinto) {
        final id = recinto['id'].toString();
        final List coords = recinto['coords'];
        final puntos = coords.map<LatLng>((c) => LatLng(c[0], c[1])).toList();
        return Polygon(
          polygonId: PolygonId('SIGPAC_$id'),
          points: puntos,
          strokeColor: Colors.green,
          fillColor: Colors.green.withOpacity(0.3),
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () async {
            final result = await _mostrarDialogoNombreDescripcion();
            if (result != null) {
              final nombre = result['nombre']!;
              final descripcion = result['descripcion'] ?? "";
              final nuevoTerreno = Terreno(
                id: 0,
                nombre: nombre,
                descripcion: descripcion,
                puntos: puntos,
                area: 0,
              );
              try {
                await crearTerreno(nuevoTerreno);
                polygonsSIGPAC.clear();
                mostrandoSIGPAC = false;
                await _refrescarTerrenos();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terreno "$nombre" importado y guardado')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error guardando terreno: $e")),
                );
              }
              setState(() {});
            }
          },
        );
      }).toSet();
      mostrandoSIGPAC = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toca un recinto para importarlo como terreno.')),
    );
  }

  Future<void> _importarDesdeSIGPAC({bool cerrarSheet = false}) async {
    if (cerrarSheet) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 150));
    }
    final bounds = await _getVisibleRegion();
    if (bounds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo obtener el área visible del mapa.")),
      );
      return;
    }

    final bbox = [
      bounds.southwest.longitude,
      bounds.southwest.latitude,
      bounds.northeast.longitude,
      bounds.northeast.latitude
    ];

    final url = Uri.parse('http://152.228.216.84:8000/api/sigpac_polygons/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bbox': bbox}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _mostrarRecintosSIGPAC(data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al importar recintos: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con SIGPAC: $e")),
      );
    }
  }

  // UI para editar terreno
  Future<void> _mostrarDialogEditar(Terreno terreno) async {
    final result = await _mostrarDialogoNombreDescripcion(
        nombre: terreno.nombre, descripcion: terreno.descripcion);
    if (result != null) {
      try {
        await editarTerreno(terreno.id, result['nombre']!, result['descripcion'] ?? "");
        await _refrescarTerrenos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terreno editado correctamente")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error editando terreno: $e")),
        );
      }
    }
  }

  // UI para eliminar terreno
  Future<void> _confirmarEliminarTerreno(Terreno terreno) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar terreno"),
        content: Text("¿Seguro que quieres eliminar \"${terreno.nombre}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Eliminar")),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await eliminarTerreno(terreno.id);
        await _refrescarTerrenos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terreno eliminado")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error eliminando terreno: $e")),
        );
      }
    }
  }

  void _mostrarInfoTerreno(Terreno terreno) async {
    final index = terrenosGuardados.indexWhere((t) => t.id == terreno.id);
    if (index == -1) return;

    setState(() {
      terrenoSeleccionadoIndex = index;
      mostrarListaTerrenos = false;
      _weatherData = null;
    });

    final url = Uri.parse('http://152.228.216.84:8000/api/terrenos/${terreno.id}/meteo/');
    setState(() => _weatherLoading = true);
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(res.body);
        });
      }
    } catch (e) {
      setState(() => _weatherData = null);
    }
    setState(() => _weatherLoading = false);

    // Centrar el mapa:
    final centro = _calcularCentroide(terreno.puntos);
    mapController.animateCamera(CameraUpdate.newLatLngZoom(centro, 17.0));
  }


  Future<void> _cargarWeather(int terrenoId) async {
    setState(() => _weatherLoading = true);
    final url = Uri.parse('http://152.228.216.84:8000/api/terrenos/$terrenoId/meteo/');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(res.body);
        });
      }
    } catch (_) {}
    setState(() => _weatherLoading = false);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: currentPosition == null
          ? const Center (child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: currentPosition!,
              zoom: 16.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.satellite,
            onTap: modoDibujo
                ? (LatLng punto) {
              setState(() {
                puntosTerreno.add(punto);
              });
            }
                : null,
            polygons: {...polygons, ...polygonsSIGPAC},
            markers: {
              ...terrainMarkers,
              ...puntosTerreno.asMap().entries.map((e) => Marker(
                markerId: MarkerId('punto_${e.key}'),
                position: e.value,
              )),
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                    ),
                    child: modoDibujo
                        ? Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.undo),
                          label: const Text("Atrás"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(110, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: puntosTerreno.isNotEmpty
                              ? () {
                            setState(() {
                              puntosTerreno.removeLast();
                            });
                          }
                              : null,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Guardar"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(110, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: puntosTerreno.length >= 3 ? _guardarTerreno : null,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text("Cancelar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(110, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () async {
                            if (puntosTerreno.isNotEmpty) {
                              final confirmar = await _confirmarCancelarDibujo();
                              if (!confirmar) return;
                            }
                            setState(() {
                              modoDibujo = false;
                              puntosTerreno.clear();
                            });
                          },
                        ),
                      ],
                    )
                        : mostrandoSIGPAC
                        ? Row(
                      key: const ValueKey('modoSIGPAC'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Recargar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _importarDesdeSIGPAC(),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text("Cancelar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              polygonsSIGPAC.clear();
                              mostrandoSIGPAC = false;
                            });
                          },
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.map),
                          label: const Text("Terrenos"),
                          onPressed: () {
                            setState(() {
                              mostrarListaTerrenos = true;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          key: const ValueKey('modoNormal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _onAnadirTerrenoPressed,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Listado de terrenos
          if (mostrarListaTerrenos)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Terrenos guardados", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                mostrarListaTerrenos = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: terrenosGuardados.length,
                        itemBuilder: (context, index) {
                          final terreno = terrenosGuardados[index];
                          return ListTile(
                            title: Text(terreno.nombre),
                            subtitle: terreno.descripcion.isNotEmpty
                                ? Text(terreno.descripcion)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _mostrarDialogEditar(terreno),
                                  tooltip: "Editar",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmarEliminarTerreno(terreno),
                                  tooltip: "Eliminar",
                                ),
                              ],
                            ),
                            onTap: () => _mostrarInfoTerreno(terreno),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Panel inferior con info ampliada del terreno seleccionado
          if (terrenoSeleccionado != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                margin: EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              terrenoSeleccionado!.nombre,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                terrenoSeleccionadoIndex = null;
                              });
                            },
                          ),
                        ],
                      ),
                      if (terrenoSeleccionado!.descripcion.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            terrenoSeleccionado!.descripcion,
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ),
                      Text(
                        "Área: ${terrenoSeleccionado!.area.toStringAsFixed(2)} m²",
                        style: const TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      if (_weatherLoading)
                        const Center(child: CircularProgressIndicator()),
                      if (_weatherData != null && _weatherData!['current_weather'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  weatherCodeToIcon(_weatherData!['current_weather']['weathercode'])['icon'],
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    weatherCodeToIcon(_weatherData!['current_weather']['weathercode'])['label'],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.calendar_view_week),
                                label: const Text('Ver previsión'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PrevisionPage(weatherData: _weatherData!),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      if (terrenosGuardados.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_left, size: 32),
                                tooltip: "Anterior terreno",
                                onPressed: terrenoSeleccionadoIndex != null && terrenoSeleccionadoIndex! > 0
                                    ? () {
                                  setState(() {
                                    terrenoSeleccionadoIndex = terrenoSeleccionadoIndex! - 1;
                                    _weatherData = null;
                                  });
                                  _mostrarInfoTerreno(terrenosGuardados[terrenoSeleccionadoIndex!]);
                                }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_right, size: 32),
                                tooltip: "Siguiente terreno",
                                onPressed: terrenoSeleccionadoIndex != null && terrenoSeleccionadoIndex! < terrenosGuardados.length - 1
                                    ? () {
                                  setState(() {
                                    terrenoSeleccionadoIndex = terrenoSeleccionadoIndex! + 1;
                                    _weatherData = null;
                                  });
                                  _mostrarInfoTerreno(terrenosGuardados[terrenoSeleccionadoIndex!]);
                                }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

