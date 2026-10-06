from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from decimal import Decimal

class Product(models.Model):
    class SellingType(models.TextChoices):
        UNIT = 'UNIT', 'Unit / Packaged'
        KG = 'KG', 'Kilogram (Weight / Loose)'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='products',
        db_index=True,
        help_text="The shopkeeper who owns this inventory record."
    )
    name = models.CharField(max_length=200, db_index=True)
    category = models.CharField(max_length=100, db_index=True)
    selling_type = models.CharField(
        max_length=10,
        choices=SellingType.choices,
        default=SellingType.UNIT,
        help_text="UNIT for packaged goods, KG for loose goods by weight."
    )
    cost_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Wholesale / cost price per unit or per KG."
    )
    price_per_unit = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Retail selling price per unit or per KG."
    )
    quantity = models.DecimalField(
        max_digits=12,
        decimal_places=3,
        default=Decimal('0.000'),
        help_text="Stock level. Stores integers for UNIT or 3-decimal values for KG."
    )
    feature_vector = models.JSONField(
        null=True,
        blank=True,
        help_text="Visual embedding vector (L2-normalized float list) generated from product image."
    )
    is_loose = models.BooleanField(
        default=False,
        db_index=True,
        help_text="True for unbranded/loose commodities (e.g., plain bags of sugar, rice, flour)."
    )
    image_url = models.URLField(max_length=500, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'shopgenie_products'
        verbose_name = 'Product'
        verbose_name_plural = 'Products'
        ordering = ['-created_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'name'],
                name='unique_product_per_shopkeeper'
            )
        ]

    def clean(self):
        super().clean()
        if self.selling_type == self.SellingType.UNIT:
            # UNIT products must have integer quantities
            if self.quantity is not None and self.quantity % 1 != 0:
                raise ValidationError({'quantity': 'UNIT products must have whole number (integer) quantities.'})

    def save(self, *args, **kwargs):
        # Automatically mark KG goods as loose if not explicitly overridden
        if self.selling_type == self.SellingType.KG and not self.is_loose:
            # Commonly known loose staples
            known_loose = {'sugar', 'salt', 'rice', 'maida', 'flour', 'dal', 'wheat', 'atta'}
            if any(staple in self.name.lower() for staple in known_loose):
                self.is_loose = True
        self.full_clean()
        super().save(*args, **kwargs)

    @property
    def formatted_quantity(self):
        if self.selling_type == self.SellingType.UNIT:
            return f"{int(self.quantity)} units"
        return f"{self.quantity:.3f} kg"

    def __str__(self):
        return f"{self.name} ({self.selling_type}) - Shopkeeper: {self.user.username}"
