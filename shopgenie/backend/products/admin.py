from django.contrib import admin
from .models import Product

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'category', 'selling_type', 'cost_price', 'price_per_unit', 'quantity', 'is_loose', 'user')
    list_filter = ('selling_type', 'is_loose', 'category')
    search_fields = ('name', 'category', 'user__username')
    readonly_fields = ('created_at', 'updated_at')
