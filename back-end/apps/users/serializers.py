from rest_framework import serializers
from .models import User, Cuadrilla

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only = True, required = False, min_length = 6)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'telefono', 'role', 'password']
        read_only_fields = ['id', 'role']

    def validate_email(self, value):
        user = self.instance
        if user is not None:
            # En edición, excluye el propio usuario
            if User.objects.filter(email=value).exclude(pk=user.pk).exists():
                raise serializers.ValidationError("Este correo ya está registrado.")
        else:
            # En creación, simplemente verifica existencia
            if User.objects.filter(email=value).exists():
                raise serializers.ValidationError("Este correo ya está registrado.")
        return value

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Este nombre de usuario ya existe.")
        return value

    def validate_telefono(self, value):
        if not value.isdigit() or len(value) < 9:
            raise serializers.ValidationError("Introduce un número de teléfono válido.")
        return value

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        if 'password' in validated_data:
            instance.set_password(validated_data.pop('password'))
        return super().update(instance, validated_data)
    
class CuadrillaSerializer(serializers.ModelSerializer):
    trabajadores = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role='WORKER'),
        many=True
    )
    responsable = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role='WORKER'),
        required=False,
        allow_null=True
    )
    trabajadores_detalle = UserSerializer(source='trabajadores', many=True, read_only=True)
    responsable_detalle = UserSerializer(source='responsable', read_only=True)

    class Meta:
        model = Cuadrilla
        fields = [
            'id', 'nombre', 'descripcion',
            'trabajadores', 'responsable',
            'trabajadores_detalle', 'responsable_detalle'
        ]