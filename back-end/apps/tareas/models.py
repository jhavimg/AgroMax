from django.db import models
from django.conf import settings

from apps.users.models import Cuadrilla

class Tarea(models.Model):
    ESTADO_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('completada', 'Completada'),
        ('no_completada', 'No completada'),
    ]
    terreno = models.ForeignKey('terrenos.Terreno', on_delete=models.CASCADE, related_name='tareas')
    trabajadores = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='tareas')
    cuadrillas = models.ManyToManyField(Cuadrilla, blank=True, related_name='tareas')
    maquinas = models.ManyToManyField('maquinaria.Maquinaria', related_name='tareas')
    descripcion = models.TextField()
    fecha_realizacion = models.DateField()
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='pendiente')
    motivo_no_completada = models.TextField(blank=True, null=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Tarea en {self.terreno.nombre} ({self.fecha_realizacion})"
