from django.urls import path
from .views import RegisterView, CustomLoginView, CustomTokenRefreshView, UserProfileView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='auth_register'),
    path('login/', CustomLoginView.as_view(), name='auth_login'),
    path('refresh/', CustomTokenRefreshView.as_view(), name='auth_refresh'),
    path('me/', UserProfileView.as_view(), name='auth_me'),
]
