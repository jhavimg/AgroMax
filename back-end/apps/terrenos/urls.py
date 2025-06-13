# terrenos/urls.py
from django.urls import path
from .views import sigpac_polygons, TerrenoDetailView, TerrenoEditView, TerrenoDeleteView, \
TerrenoListCreateView, TerrenoMeteoView

urlpatterns = [
    path('sigpac_polygons/', sigpac_polygons, name='sigpac_polygons'),
    path('terrenos/', TerrenoListCreateView.as_view(), name='terrenos'),
    path('terrenos/<int:pk>/', TerrenoDetailView.as_view(), name='detalle_terreno'),
    path('terrenos/<int:pk>/editar/', TerrenoEditView.as_view(), name='editar_terreno'),
    path('terrenos/<int:pk>/eliminar/', TerrenoDeleteView.as_view(), name='eliminar_terreno'), 
    path('terrenos/<int:pk>/meteo/', TerrenoMeteoView.as_view(), name='terreno_meteo'),
]
