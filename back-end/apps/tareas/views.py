from rest_framework import generics
from .models import Tarea
from .serializers import TareaSerializer

class TareaListCreateView(generics.ListCreateAPIView):
    queryset = Tarea.objects.all().order_by('-fecha_realizacion')
    serializer_class = TareaSerializer

class TareaDetailView(generics.RetrieveAPIView):
    queryset = Tarea.objects.all()
    serializer_class = TareaSerializer

class TareaEditView(generics.UpdateAPIView):
    queryset = Tarea.objects.all()
    serializer_class = TareaSerializer

class TareaDeleteView(generics.DestroyAPIView):
    queryset = Tarea.objects.all()
    serializer_class = TareaSerializer
