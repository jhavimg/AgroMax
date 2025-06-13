from django.db import models

class Terreno(models.Model):
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True)  
    puntos = models.JSONField()                         # Lista de [lat, lon]
    area = models.FloatField(null=True, blank=True)     # Área en m²

    # Centroide del polígono
    centroide_lat = models.FloatField(null = True, blank = True)
    centroide_lon = models.FloatField(null = True, blank = True)

    def __str__(self):
        return self.nombre
