from rest_framework import serializers
from decimal import Decimal
from .models import Product

class ProductSerializer(serializers.ModelSerializer):
    formatted_quantity = serializers.ReadOnlyField()

    class Meta:
        model = Product
        fields = [
            'id',
            'user',
            'name',
            'category',
            'selling_type',
            'cost_price',
            'price_per_unit',
            'quantity',
            'formatted_quantity',
            'feature_vector',
            'is_loose',
            'image_url',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'user', 'formatted_quantity', 'created_at', 'updated_at']


class ProductRegistrationSerializer(serializers.ModelSerializer):
    feature_vector = serializers.ListField(
        child=serializers.FloatField(),
        required=False,
        allow_null=True
    )

    class Meta:
        model = Product
        fields = [
            'name',
            'category',
            'selling_type',
            'cost_price',
            'price_per_unit',
            'quantity',
            'feature_vector',
            'is_loose',
            'image_url'
        ]

    def validate_cost_price(self, value):
        if value < 0:
            raise serializers.ValidationError("Cost price must be greater than or equal to 0.")
        return value

    def validate_price_per_unit(self, value):
        if value <= 0:
            raise serializers.ValidationError("Price per unit must be greater than 0.")
        return value

    def validate_quantity(self, value):
        if value < 0:
            raise serializers.ValidationError("Quantity cannot be negative.")
        return value

    def validate(self, attrs):
        selling_type = attrs.get('selling_type')
        quantity = attrs.get('quantity')

        if selling_type == Product.SellingType.UNIT:
            if quantity is not None and quantity % 1 != 0:
                raise serializers.ValidationError({
                    "quantity": "Packaged items sold by UNIT must have an integer quantity (e.g. 5, 20)."
                })

        return attrs

    def create(self, validated_data):
        user = self.context['request'].user
        product = Product.objects.create(user=user, **validated_data)
        return product


class ProductMatchRequestSerializer(serializers.Serializer):
    """
    Accepts either an uploaded frame (multipart or base64) or triggers
    Django to capture a live frame directly from the ESP32-CAM over the network.
    """
    image_base64 = serializers.CharField(required=False, allow_blank=True)
    esp32_cam_url = serializers.URLField(required=False, allow_blank=True)
    capture_from_esp32 = serializers.BooleanField(default=False)
    similarity_threshold = serializers.FloatField(required=False, default=0.78, min_value=0.1, max_value=1.0)
    top_k = serializers.IntegerField(required=False, default=5, min_value=1, max_value=20)
