from django.urls import path
from .views import ProductListCreateView, ProductDetailView, ProductMatchView

urlpatterns = [
    path('', ProductListCreateView.as_view(), name='product_list'),
    path('register/', ProductListCreateView.as_view(), name='product_register'),
    path('match/', ProductMatchView.as_view(), name='product_match'),
    path('<int:pk>/', ProductDetailView.as_view(), name='product_detail'),
]
