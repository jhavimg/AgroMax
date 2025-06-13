from django.urls import path
from .views import TareaListCreateView, TareaDetailView, TareaEditView, TareaDeleteView

urlpatterns = [
    path('tareas/', TareaListCreateView.as_view(), name='tareas'),
    path('tareas/<int:pk>/', TareaDetailView.as_view(), name='detalle_tarea'),
    path('tareas/<int:pk>/editar/', TareaEditView.as_view(), name='editar_tarea'),
    path('tareas/<int:pk>/eliminar/', TareaDeleteView.as_view(), name='eliminar_tarea'),
]
