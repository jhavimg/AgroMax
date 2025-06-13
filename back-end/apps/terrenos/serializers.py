from rest_framework import serializers
from .models import Terreno
import math

def calcular_area_geodesica(puntos):
    if len(puntos) < 3:
        return 0.0
    R = 6378137
    area = 0.0
    for i in range(len(puntos)):
        lat1, lon1 = puntos[i]
        lat2, lon2 = puntos[(i + 1) % len(puntos)]
        area += math.radians(lon2 - lon1) * (2 + math.sin(math.radians(lat1)) + math.sin(math.radians(lat2)))
    area = area * (R ** 2) / 2.0
    return abs(area)

def calcular_centroide(puntos):
    # Fórmula del centroide simple para polígonos planos (no geodésico, suficiente para áreas pequeñas)
    if len(puntos) == 0:
        return None, None
    lat = sum(p[0] for p in puntos) / len(puntos)
    lon = sum(p[1] for p in puntos) / len(puntos)
    return lat, lon

class TerrenoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Terreno
        fields = ['id', 'nombre', 'descripcion', 'puntos', 'area', 'centroide_lat', 'centroide_lon']
        read_only_fields = ['area', 'centroide_lat', 'centroide_lon']

    def validate_puntos(self, value):
        if not isinstance(value, list) or len(value) < 3:
            raise serializers.ValidationError("Se requieren al menos 3 puntos.")
        for p in value:
            if not isinstance(p, list) or len(p) != 2:
                raise serializers.ValidationError("Cada punto debe ser una lista [lat, lng].")
        return value

    def create(self, validated_data):
        puntos = validated_data['puntos']
        area = calcular_area_geodesica(puntos)
        lat, lon = calcular_centroide(puntos)
        validated_data['area'] = area
        validated_data['centroide_lat'] = lat
        validated_data['centroide_lon'] = lon
        return super().create(validated_data)

    def update(self, instance, validated_data):
        if 'puntos' in validated_data:
            puntos = validated_data['puntos']
            area = calcular_area_geodesica(puntos)
            lat, lon = calcular_centroide(puntos)
            validated_data['area'] = area
            validated_data['centroide_lat'] = lat
            validated_data['centroide_lon'] = lon
        return super().update(instance, validated_data)

class TerrenoEditSerializer(serializers.ModelSerializer):
    class Meta:
        model = Terreno
        fields = ['nombre', 'descripcion']