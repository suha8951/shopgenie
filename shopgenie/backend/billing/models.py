from django.db import models
from django.conf import settings
from decimal import Decimal
from products.models import Product

class Invoice(models.Model):
    class Status(models.TextChoices):
        DRAFT = 'DRAFT', 'Draft / In-Progress'
        COMPLETED = 'COMPLETED', 'Completed / Paid'
        CANCELLED = 'CANCELLED', 'Cancelled'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='invoices',
        db_index=True,
        help_text="The shopkeeper who issued this invoice."
    )
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Server-calculated total bill amount."
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.COMPLETED
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'shopgenie_invoices'
        verbose_name = 'Invoice'
        verbose_name_plural = 'Invoices'
        ordering = ['-created_at']

    def recalculate_total(self):
        """Atomically sums up all associated invoice items."""
        total = sum((item.total_price for item in self.items.all()), Decimal('0.00'))
        self.total_amount = total
        self.save(update_fields=['total_amount', 'updated_at'])
        return total

    def __str__(self):
        return f"Invoice #{self.id} - User: {self.user.username} - Total: ₹{self.total_amount}"


class InvoiceItem(models.Model):
    invoice = models.ForeignKey(
        Invoice,
        on_delete=models.CASCADE,
        related_name='items',
        db_index=True
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.PROTECT,
        related_name='invoice_items'
    )
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        help_text="Quantity billed (integer for UNIT, decimal for KG)."
    )
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Captured selling price at time of purchase."
    )
    total_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text="Backend calculated: quantity * unit_price"
    )

    class Meta:
        db_table = 'shopgenie_invoice_items'
        verbose_name = 'Invoice Item'
        verbose_name_plural = 'Invoice Items'

    def save(self, *args, **kwargs):
        # Strict backend calculation — never trust client-supplied total_price
        self.total_price = (Decimal(str(self.quantity)) * Decimal(str(self.unit_price))).quantize(Decimal('0.01'))
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.product.name} x {self.quantity} = ₹{self.total_price}"
