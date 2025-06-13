from django.urls import path
from .views import (
    DashboardResumenView,
    DashboardTareasPorMesView,
    DashboardTareasPorEstadoView,
    DashboardTopTrabajadoresView,
    DashboardTopCuadrillasView,
    DashboardTareasPorTerrenoView,
    DashboardMaquinariaResumenView,
)

urlpatterns = [
    path('resumen/', DashboardResumenView.as_view(), name='dashboard-resumen'),
    path('tareas_por_mes/', DashboardTareasPorMesView.as_view(), name='dashboard-tareas-por-mes'),
    path('tareas_por_estado/', DashboardTareasPorEstadoView.as_view(), name='dashboard-tareas-por-estado'),
    path('top_trabajadores/', DashboardTopTrabajadoresView.as_view(), name='dashboard-top-trabajadores'),
    path('top_cuadrillas/', DashboardTopCuadrillasView.as_view(), name='dashboard-top-cuadrillas'),
    path('tareas_por_terreno/', DashboardTareasPorTerrenoView.as_view(), name='dashboard-tareas-por-terreno'),
    path('maquinaria_resumen/', DashboardMaquinariaResumenView.as_view(), name='dashboard-maquinaria-resumen'),
]
