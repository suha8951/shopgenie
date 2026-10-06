from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from decimal import Decimal
from products.models import Product
from billing.models import Invoice, InvoiceItem

User = get_user_model()

class BillingCheckoutTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='shopkeeper_sam',
            email='sam@shopgenie.local',
            password='Password123!'
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

        self.unit_product = Product.objects.create(
            user=self.user,
            name='Good Day Cookies',
            category='Biscuits',
            selling_type='UNIT',
            cost_price=Decimal('15.00'),
            price_per_unit=Decimal('20.00'),
            quantity=Decimal('10.000')
        )
        self.kg_product = Product.objects.create(
            user=self.user,
            name='Refined Sugar',
            category='Commodities',
            selling_type='KG',
            cost_price=Decimal('38.00'),
            price_per_unit=Decimal('45.00'),
            quantity=Decimal('50.000'),
            is_loose=True
        )

    def test_unit_checkout_decrements_stock_and_computes_total(self):
        payload = {
            'product_id': self.unit_product.id,
            'quantity': '2.000'
        }
        res = self.client.post('/api/checkout/accept/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # Verify stock decremented: 10 - 2 = 8
        self.unit_product.refresh_from_db()
        self.assertEqual(self.unit_product.quantity, Decimal('8.000'))

        # Verify total amount calculated by backend: 2 * 20.00 = 40.00
        invoice_id = res.data['invoice']['id']
        invoice = Invoice.objects.get(id=invoice_id)
        self.assertEqual(invoice.total_amount, Decimal('40.00'))

    def test_kg_checkout_fractional_weight(self):
        payload = {
            'product_id': self.kg_product.id,
            'quantity': '2.500'
        }
        res = self.client.post('/api/checkout/accept/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # 50 - 2.5 = 47.5
        self.kg_product.refresh_from_db()
        self.assertEqual(self.kg_product.quantity, Decimal('47.500'))

        # 2.5 * 45.00 = 112.50
        invoice_id = res.data['invoice']['id']
        invoice = Invoice.objects.get(id=invoice_id)
        self.assertEqual(invoice.total_amount, Decimal('112.50'))

    def test_insufficient_stock_rejection(self):
        payload = {
            'product_id': self.unit_product.id,
            'quantity': '15.000'
        }
        res = self.client.post('/api/checkout/accept/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_409_CONFLICT)
        self.assertIn('Insufficient stock', res.data['error'])
