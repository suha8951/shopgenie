from django.urls import path
from .views import ESP32CaptureFrameView, GenerateEmbeddingView

urlpatterns = [
    path('capture/', ESP32CaptureFrameView.as_view(), name='vision_capture'),
    path('embed/', GenerateEmbeddingView.as_view(), name='vision_embed'),
]
