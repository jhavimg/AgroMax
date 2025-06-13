from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from django.db.models import Count, Q
from django.db.models.functions import TruncMonth
from apps.terrenos.models import Terreno
from apps.users.models import User, Cuadrilla
from apps.tareas.models import Tarea
from apps.maquinaria.models import Maquinaria

class DashboardResumenView(APIView):
    permission_classes = [IsAdminUser]
    def get(self, request):
        return Response({
            "num_terrenos": Terreno.objects.count(),
            "num_trabajadores": User.objects.filter(role='WORKER').count(),
            "num_cuadrillas": Cuadrilla.objects.count(),
            "num_maquinaria": Maquinaria.objects.count(),
            "num_tareas": Tarea.objects.count(),
            "tareas_pendientes": Tarea.objects.filter(estado='pendiente').count(),
            "tareas_completadas": Tarea.objects.filter(estado='completada').count(),
            "tareas_no_completadas": Tarea.objects.filter(estado='no_completada').count(),
        })

class DashboardTareasPorMesView(APIView):
    permission_classes = [IsAdminUser]
    def get(self, request):
        tareas = (Tarea.objects
                  .annotate(mes=TruncMonth('fecha_realizacion'))
                  .values('mes')
                  .annotate(total=Count('id'))
                  .order_by('mes'))
        # Devuelve: [{"mes": "2025-05-01", "total": 7}, ...]
        return Response(tareas)

class DashboardTareasPorEstadoView(APIView):
    permission_classes = [IsAdminUser]
    def get(self, request):
        conteos = Tarea.objects.values('estado').annotate(total=Count('id'))
        return Response(conteos)

class DashboardTopTrabajadoresView(APIView):
    permission_classes = [IsAdminUser]
    def get(self, request):
        workers = User.objects.filter(role='WORKER')
        result = []
        for worker in workers:
            # Tareas directas (ManyToMany)
            direct_tasks = set(Tarea.objects.filter(trabajadores=worker).values_list('id', flat=True))
            # Cuadrillas a las que pertenece (relación inversa)
            cuadrilla_ids = worker.cuadrilla_set.values_list('id', flat=True)
            cuadrilla_tasks = set(Tarea.objects.filter(cuadrillas__in=cuadrilla_ids).values_list('id', flat=True))
            total_tasks = direct_tasks | cuadrilla_tasks  # unión para quitar duplicados
            result.append({
                'id': worker.id,
                'username': worker.username,
                'num_tareas': len(total_tasks)
            })
        # Ordena y selecciona top 5
        result = sorted(result, key=lambda x: x['num_tareas'], reverse=True)[:5]
        return Response(result)

class DashboardTopCuadrillasView(APIView):
    permission_classes = [IsAdminUser]
    def get(self, request):
        top = (Cuadrilla.objects
               .annotate(num_tareas=Count('tareas'))
               .order_by('-num_tareas')[:5]
               .values('id', 'nombre', 'num_tareas'))
        return Response(list(top))

class DashboardTareasPorTerrenoView(APIView):
    permission_classes = [IsAdminUser]
    def get(self, request):
        datos = (Terreno.objects
                 .annotate(num_tareas=Count('tareas'))
                 .order_by('-num_tareas')
                 .values('id', 'nombre', 'num_tareas'))
        return Response(list(datos))

class DashboardMaquinariaResumenView(APIView):
    permission_classes = [IsAdminUser]
    def get(self, request):
        maquinas = (Maquinaria.objects
                    .annotate(num_tareas=Count('tareas'))
                    .order_by('-num_tareas')
                    .values('id', 'nombre', 'num_tareas'))
        return Response(list(maquinas))
