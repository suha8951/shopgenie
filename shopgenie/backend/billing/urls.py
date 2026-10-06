from django.urls import path
from .views import (
    CheckoutAcceptView,
    InvoiceListView,
    InvoiceDetailView,
    AnalyticsView
)

urlpatterns = [
    path('accept/', CheckoutAcceptView.as_view(), name='checkout_accept'),
    path('invoices/', InvoiceListView.as_view(), name='invoice_list'),
    path('invoices/<int:pk>/', InvoiceDetailView.as_view(), name='invoice_detail'),
    path('analytics/', AnalyticsView.as_view(), name='checkout_analytics'),
]
