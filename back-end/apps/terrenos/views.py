import requests
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

from rest_framework import status
from .models import Terreno
from .serializers import TerrenoSerializer, TerrenoEditSerializer
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import generics
from django.shortcuts import get_object_or_404

def extract_polygons(overpass_json):
    elements = overpass_json['elements']
    node_dict = {node['id']: (node['lat'], node['lon']) for node in elements if node['type'] == 'node'}
    way_dict = {way['id']: way for way in elements if way['type'] == 'way'}
    polygons = []

    # Ways simples
    for elem in elements:
        if elem['type'] == 'way' and 'nodes' in elem:
            coords = [ [node_dict[n][0], node_dict[n][1]] for n in elem['nodes'] if n in node_dict ]
            if len(coords) > 2:
                polygons.append({
                    'id': elem.get('id'),
                    'tags': elem.get('tags', {}),
                    'coords': coords
                })
    # Relaciones multipolígono
    for elem in elements:
        if elem['type'] == 'relation' and 'members' in elem:
            outer_polygons = []
            for member in elem['members']:
                if member.get('role') == 'outer' and member.get('type') == 'way':
                    way = way_dict.get(member['ref'])
                    if way and 'nodes' in way:
                        coords = [ [node_dict[n][0], node_dict[n][1]] for n in way['nodes'] if n in node_dict ]
                        if len(coords) > 2:
                            outer_polygons.append(coords)
            for coords in outer_polygons:
                polygons.append({
                    'id': elem.get('id'),
                    'tags': elem.get('tags', {}),
                    'coords': coords
                })
    return polygons


@csrf_exempt
def sigpac_polygons(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        bbox = data.get('bbox')
        if not bbox or len(bbox) != 4:
            return JsonResponse({'error': 'bbox inválido'}, status=400)
        # bbox: [minLon, minLat, maxLon, maxLat]
        bbox_str = f"{bbox[1]},{bbox[0]},{bbox[3]},{bbox[2]}"  # sur,oeste,norte,este
        # Overpass query for farmland polygons in bbox
        overpass_url = "https://overpass-api.de/api/interpreter"
        query = f"""
        [out:json][timeout:25];
        (
          way["landuse"~"farmland|orchard|vineyard|meadow|grassland|pasture"]({bbox_str});
          relation["landuse"~"farmland|orchard|vineyard|meadow|grassland|pasture"]({bbox_str});
        );
        out body;
        >;
        out skel qt;
        """
        response = requests.post(overpass_url, data={'data': query})
        if response.status_code == 200:
            overpass_json = response.json()
            polygons = extract_polygons(overpass_json)
            return JsonResponse(polygons, safe=False)
        else:
            return JsonResponse({'error': 'Error en Overpass API', 'status_code': response.status_code}, status=500)
    return JsonResponse({'error': 'Método no permitido'}, status=405)

class TerrenoListCreateView(generics.ListCreateAPIView):
    queryset = Terreno.objects.all()
    serializer_class = TerrenoSerializer

class TerrenoDetailView(generics.RetrieveAPIView):
    queryset = Terreno.objects.all()
    serializer_class = TerrenoSerializer

# Editar solo nombre/descripcion
class TerrenoEditView(generics.UpdateAPIView):
    queryset = Terreno.objects.all()
    serializer_class = TerrenoEditSerializer

# Eliminar terreno
class TerrenoDeleteView(generics.DestroyAPIView):
    queryset = Terreno.objects.all()
    serializer_class = TerrenoSerializer

class TerrenoMeteoView(APIView):
    def get(self, request, pk):
        terreno = get_object_or_404(Terreno, pk = pk)
        lat = terreno.centroide_lat
        lon = terreno.centroide_lon
        if lat is None or lon is None:
            return Response({"error": "Este terreno no tiene centroide asignado"}, status=400)
        
        # Open-Meteo API URL
        url = (
            "https://api.open-meteo.com/v1/forecast"
            f"?latitude={lat}&longitude={lon}"
            "&current_weather=true"
            "&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode"
            "&forecast_days=7"
            "&timezone=Europe/Madrid"
        )

        try:
            r = requests.get(url, timeout = 10)
            if r.status_code != 200:
                return Response({"error": "Error consultando Open-Meteo"}, status=502)
            meteo = r.json()
        except Exception as e:
            return Response({"error": f"Error conectando con Open-Meteo: {str(e)}"}, status=500)
        
        # Respuesta: tiempo actual + previsión diaría (7 días)
        return Response({
            "terreno": terreno.nombre,
            "centroide": {"lat": lat, "lon": lon},
            "current_weather": meteo.get("current_weather", {}),
            "daily": meteo.get("daily", {}),
        })