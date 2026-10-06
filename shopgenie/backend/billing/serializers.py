from rest_framework import serializers
from decimal import Decimal
from .models import Invoice, InvoiceItem
from products.models import Product
from products.serializers import ProductSerializer

class InvoiceItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_category = serializers.CharField(source='product.category', read_only=True)
    selling_type = serializers.CharField(source='product.selling_type', read_only=True)

    class Meta:
        model = InvoiceItem
        fields = [
            'id',
            'product',
            'product_name',
            'product_category',
            'selling_type',
            'quantity',
            'unit_price',
            'total_price'
        ]
        read_only_fields = ['id', 'product_name', 'product_category', 'selling_type', 'unit_price', 'total_price']


class InvoiceSerializer(serializers.ModelSerializer):
    items = InvoiceItemSerializer(many=True, read_only=True)
    item_count = serializers.SerializerMethodField()

    class Meta:
        model = Invoice
        fields = [
            'id',
            'user',
            'total_amount',
            'status',
            'items',
            'item_count',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'user', 'total_amount', 'item_count', 'created_at', 'updated_at']

    def get_item_count(self, obj):
        return obj.items.count()


class CheckoutAcceptSerializer(serializers.Serializer):
    """
    Accepts item checkout request.
    Stock validation and price calculations are strictly enforced by the backend.
    """
    product_id = serializers.IntegerField(required=True)
    quantity = serializers.DecimalField(max_digits=10, decimal_places=3, min_value=Decimal('0.001'))
    invoice_id = serializers.IntegerField(required=False, allow_null=True)

    def validate_quantity(self, value):
        if value <= Decimal('0'):
            raise serializers.ValidationError("Quantity must be greater than zero.")
        return value
