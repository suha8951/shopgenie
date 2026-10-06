import base64
from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from django.conf import settings
from .services import VisionService

class ESP32CaptureFrameView(APIView):
    """
    POST /api/vision/capture/
    Pulls a single JPEG frame from the configured ESP32-CAM Wi-Fi stream
    and returns it as base64 and embedding for preview / product enrollment.
    """
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, *args, **kwargs):
        cam_url = request.data.get('esp32_cam_url') or getattr(settings, 'DEFAULT_ESP32_STREAM_URL', 'http://192.168.1.100:81/stream')
        
        frame_bytes, err = VisionService.capture_frame_from_esp32(cam_url)
        if err or not frame_bytes:
            return Response(
                {'error': f'Failed to capture from ESP32-CAM ({cam_url}): {err}'},
                status=status.HTTP_502_BAD_GATEWAY
            )

        embedding, is_loose = VisionService.get_embedding_from_cv_engine(frame_bytes)

        return Response({
            'message': 'Frame captured successfully.',
            'image_base64': base64.b64encode(frame_bytes).decode('utf-8'),
            'feature_vector': embedding,
            'is_loose': is_loose,
            'frame_size_bytes': len(frame_bytes)
        }, status=status.HTTP_200_OK)


class GenerateEmbeddingView(APIView):
    """
    POST /api/vision/embed/
    Accepts an uploaded image file or base64 string and returns its MobileNetV3 embedding vector.
    Used during 'Add Stock' to compute the visual vector for new products.
    """
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, *args, **kwargs):
        uploaded_file = request.FILES.get('image')
        image_base64 = request.data.get('image_base64')

        image_bytes = None
        if uploaded_file:
            image_bytes = uploaded_file.read()
        elif image_base64:
            try:
                if ',' in image_base64:
                    image_base64 = image_base64.split(',', 1)[1]
                image_bytes = base64.b64decode(image_base64)
            except Exception as e:
                return Response({'error': f'Invalid base64 payload: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

        if not image_bytes:
            return Response({'error': 'Image file or base64 required.'}, status=status.HTTP_400_BAD_REQUEST)

        embedding, is_loose = VisionService.get_embedding_from_cv_engine(image_bytes)

        return Response({
            'feature_vector': embedding,
            'is_loose': is_loose,
            'vector_length': len(embedding) if embedding else 0
        }, status=status.HTTP_200_OK)
