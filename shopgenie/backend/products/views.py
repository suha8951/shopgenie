import base64
from rest_framework import generics, status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from django.conf import settings
from .models import Product
from .serializers import (
    ProductSerializer,
    ProductRegistrationSerializer,
    ProductMatchRequestSerializer
)
from vision.services import VisionService

class ProductListCreateView(generics.ListCreateAPIView):
    """
    GET /api/products/
    Returns the authenticated shopkeeper's active inventory.
    
    POST /api/products/register/
    Registers a new product (UNIT or KG) under the authenticated user.
    """
    permission_classes = (permissions.IsAuthenticated,)

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ProductRegistrationSerializer
        return ProductSerializer

    def get_queryset(self):
        # Strict multi-tenant isolation: Only return products of the authenticated user
        return Product.objects.filter(user=self.request.user).order_by('-created_at')

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        product = serializer.save()
        return Response(ProductSerializer(product).data, status=status.HTTP_201_CREATED)


class ProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET, PUT, PATCH, DELETE /api/products/<int:pk>/
    Access or update an individual product belonging strictly to request.user.
    """
    serializer_class = ProductSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        return Product.objects.filter(user=self.request.user)


class ProductMatchView(APIView):
    """
    POST /api/products/match/
    Visual item recognition endpoint:
    - Accepts an uploaded frame, base64 image, or requests Django to capture directly from ESP32-CAM.
    - Extracts visual embedding using MobileNetV3 and checks for plain bag / loose commodity characteristics.
    - Performs cosine similarity against the authenticated user's registered products.
    - Never returns another user's products.
    """
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, *args, **kwargs):
        serializer = ProductMatchRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        cam_url = data.get('esp32_cam_url') or getattr(settings, 'DEFAULT_ESP32_STREAM_URL', 'http://192.168.1.100:81/stream')
        capture_from_esp32 = data.get('capture_from_esp32', False)
        image_base64 = data.get('image_base64')
        uploaded_file = request.FILES.get('image')
        threshold = data.get('similarity_threshold', getattr(settings, 'CV_SIMILARITY_THRESHOLD', 0.78))

        # Obtain the raw image bytes
        image_bytes = None
        if uploaded_file:
            image_bytes = uploaded_file.read()
        elif image_base64:
            try:
                # Handle possible data URL prefix like "data:image/jpeg;base64,"
                if ',' in image_base64:
                    image_base64 = image_base64.split(',', 1)[1]
                image_bytes = base64.b64decode(image_base64)
            except Exception as e:
                return Response({'error': f'Invalid base64 image: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
        elif capture_from_esp32 or cam_url:
            image_bytes, err = VisionService.capture_frame_from_esp32(cam_url)
            if err or not image_bytes:
                return Response(
                    {'error': f'Failed to capture frame from ESP32-CAM ({cam_url}): {err}'},
                    status=status.HTTP_502_BAD_GATEWAY
                )
        else:
            return Response(
                {'error': 'Provide either an uploaded image file, base64 string, or enable capture_from_esp32.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Delegate to vision matching engine strictly for this shopkeeper's catalog
        match_result = VisionService.match_product(
            user=request.user,
            image_bytes=image_bytes,
            similarity_threshold=threshold
        )

        return Response(match_result, status=status.HTTP_200_OK)
