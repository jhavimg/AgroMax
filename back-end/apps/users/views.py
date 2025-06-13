from rest_framework import viewsets
from rest_framework.permissions import IsAdminUser
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status, generics, permissions

from .models import User, Cuadrilla
from .serializers import UserSerializer, CuadrillaSerializer


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser]

class CurrentUserView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data = request.data, partial = True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status = status.HTTP_400_BAD_REQUEST)
    
class CreateWorkerView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request):
        data = request.data.copy()
        data['role'] = 'WORKER'
        serializer = UserSerializer(data = data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status = status.HTTP_201_CREATED)
        return Response(serializer.errors, status = status.HTTP_400_BAD_REQUEST)
    

class WorkersListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        trabajadores = User.objects.filter(role = 'WORKER')
        serializer = UserSerializer(trabajadores, many = True)
        return Response(serializer.data)
    
class CuadrillaListCreateView(generics.ListCreateAPIView):
    queryset = Cuadrilla.objects.all()
    serializer_class = CuadrillaSerializer
    permission_classes = [permissions.IsAuthenticated]

class CuadrillaDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Cuadrilla.objects.all()
    serializer_class = CuadrillaSerializer
    permission_classes = [permissions.IsAuthenticated]