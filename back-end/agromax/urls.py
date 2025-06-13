from django.contrib import admin
from django.urls import path, include

from rest_framework_simplejwt.views import TokenRefreshView
from apps.accounts.views import CustomTokenObtainPairView

urlpatterns = [
    path("admin/", admin.site.urls),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path("api/users/", include("apps.users.urls")),
    path("api/auth/", include("apps.accounts.urls")),
    path('api/maquinaria/', include('apps.maquinaria.urls')),
    path('api/', include('apps.terrenos.urls')),
    path('api/', include('apps.tareas.urls')),
    path('api/dashboard/', include('apps.dashboard.urls')),
]
