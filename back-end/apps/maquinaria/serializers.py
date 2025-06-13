from rest_framework import serializers
from .models import Maquinaria

class MaquinariaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Maquinaria
        fields = ['id', 'nombre', 'descripcion']
