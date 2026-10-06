from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, UserSerializer, CustomTokenObtainPairSerializer

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    """
    POST /api/auth/register/
    Registers a new shopkeeper account and returns JWT credentials immediately.
    """
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Generate JWT tokens for instant seamless onboarding
        refresh = RefreshToken.for_user(user)

        return Response({
            'message': 'Account registered successfully.',
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        }, status=status.HTTP_201_CREATED)


class CustomLoginView(TokenObtainPairView):
    """
    POST /api/auth/login/
    Authenticates shopkeeper credentials and issues JWT access and refresh tokens.
    """
    permission_classes = (permissions.AllowAny,)
    serializer_class = CustomTokenObtainPairSerializer


class CustomTokenRefreshView(TokenRefreshView):
    """
    POST /api/auth/refresh/
    Refreshes an expired JWT access token using a valid refresh token.
    """
    permission_classes = (permissions.AllowAny,)


class UserProfileView(generics.RetrieveAPIView):
    """
    GET /api/auth/me/
    Retrieves the authenticated shopkeeper's profile.
    """
    serializer_class = UserSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_object(self):
        return self.request.user
