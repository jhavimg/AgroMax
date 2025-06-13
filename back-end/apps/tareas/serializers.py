from rest_framework import serializers
from .models import Tarea
from apps.terrenos.models import Terreno
from apps.maquinaria.models import Maquinaria
from apps.users.models import Cuadrilla
from apps.users.serializers import CuadrillaSerializer
from django.contrib.auth import get_user_model

User = get_user_model()

class TerrenoSimpleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Terreno
        fields = ['id', 'nombre']

class UserSimpleSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username']

class MaquinariaSimpleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Maquinaria
        fields = ['id', 'nombre']

class TareaSerializer(serializers.ModelSerializer):
    terreno = serializers.PrimaryKeyRelatedField(queryset=Terreno.objects.all(), write_only=True)
    trabajadores = serializers.PrimaryKeyRelatedField(queryset=User.objects.all(), many=True, write_only=True)
    cuadrillas = serializers.PrimaryKeyRelatedField(
        queryset=Cuadrilla.objects.all(), many=True, required=False
    )
    cuadrillas_detalle = CuadrillaSerializer(source='cuadrillas', many=True, read_only=True)
    maquinas = serializers.PrimaryKeyRelatedField(queryset=Maquinaria.objects.all(), many=True, write_only=True)

    terreno_detalle = TerrenoSimpleSerializer(source='terreno', read_only=True)
    trabajadores_detalle = UserSimpleSerializer(source='trabajadores', many=True, read_only=True)
    maquinas_detalle = MaquinariaSimpleSerializer(source='maquinas', many=True, read_only=True)

    todos_trabajadores = serializers.SerializerMethodField()

    def get_todos_trabajadores(self, obj):
        # IDs de trabajadores individuales
        individuales = list(obj.trabajadores.all())
        # IDs de todos los trabajadores en cuadrillas asignadas (sin duplicados)
        cuadrilla_users = []
        for cuadrilla in obj.cuadrillas.all():
            cuadrilla_users.extend(list(cuadrilla.trabajadores.all()))
        # Quita duplicados y los convierte en UserSimpleSerializer
        todos = {u.id: u for u in individuales + cuadrilla_users}
        return UserSimpleSerializer(todos.values(), many=True).data

    class Meta:
        model = Tarea
        fields = [
            'id',
            'terreno', 'trabajadores', 'maquinas',
            'cuadrillas', 'cuadrillas_detalle',
            'terreno_detalle', 'trabajadores_detalle', 'maquinas_detalle',
            'descripcion', 'fecha_realizacion',
            'estado', 'motivo_no_completada',
            'fecha_creacion', 'fecha_actualizacion',
            'todos_trabajadores',
        ]

