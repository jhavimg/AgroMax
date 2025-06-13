from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet, CurrentUserView, CreateWorkerView, WorkersListView, CuadrillaListCreateView, CuadrillaDetailView

router = DefaultRouter()
router.register(r'', UserViewSet)

urlpatterns = [
    path('me/', CurrentUserView.as_view(), name = 'current_user'),
    path('create-worker/', CreateWorkerView.as_view(), name='create_worker'),
    path('workers/', WorkersListView.as_view(), name='workers_list'),
    path('cuadrillas/', CuadrillaListCreateView.as_view(), name='cuadrilla-list-create'),
    path('cuadrillas/<int:pk>/', CuadrillaDetailView.as_view(), name='cuadrilla-detail'),
    path('', include(router.urls)),
]