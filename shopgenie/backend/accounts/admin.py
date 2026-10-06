from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser

@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ('id', 'username', 'email', 'shop_name', 'is_staff', 'date_joined')
    search_fields = ('username', 'email', 'shop_name')
    fieldsets = UserAdmin.fieldsets + (
        ('Shop Info', {'fields': ('shop_name',)}),
    )
