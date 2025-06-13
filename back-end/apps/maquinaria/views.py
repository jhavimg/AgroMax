from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Maquinaria
from .serializers import MaquinariaSerializer

class MaquinariaViewSet(viewsets.ModelViewSet):
    queryset = Maquinaria.objects.all()
    serializer_class = MaquinariaSerializer
    permission_classes = [IsAuthenticated]
