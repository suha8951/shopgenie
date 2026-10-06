from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from decimal import Decimal
from products.models import Product

User = get_user_model()

class ProductModelAndAPITests(TestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            username='user1',
            email='user1@shopgenie.local',
            password='TestPassword123!'
        )
        self.user2 = User.objects.create_user(
            username='user2',
            email='user2@shopgenie.local',
            password='TestPassword123!'
        )
        self.client1 = APIClient()
        self.client1.force_authenticate(user=self.user1)

        self.client2 = APIClient()
        self.client2.force_authenticate(user=self.user2)

    def test_register_unit_product(self):
        payload = {
            'name': 'Parle-G 100g',
            'category': 'Biscuits',
            'selling_type': 'UNIT',
            'cost_price': '8.50',
            'price_per_unit': '10.00',
            'quantity': '50.000',
            'is_loose': False
        }
        res = self.client1.post('/api/products/register/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['name'], 'Parle-G 100g')
        self.assertEqual(res.data['selling_type'], 'UNIT')

    def test_register_kg_loose_product(self):
        payload = {
            'name': 'Basmati Rice Premium',
            'category': 'Grains',
            'selling_type': 'KG',
            'cost_price': '75.00',
            'price_per_unit': '95.50',
            'quantity': '125.750',
            'is_loose': True
        }
        res = self.client1.post('/api/products/register/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['selling_type'], 'KG')
        self.assertTrue(res.data['is_loose'])

    def test_strict_tenant_isolation(self):
        # User 1 registers item
        Product.objects.create(
            user=self.user1,
            name='User1 Soap',
            category='Hygiene',
            selling_type='UNIT',
            cost_price=Decimal('20.00'),
            price_per_unit=Decimal('25.00'),
            quantity=Decimal('10.000')
        )
        # User 2 registers item
        Product.objects.create(
            user=self.user2,
            name='User2 Tea',
            category='Beverages',
            selling_type='UNIT',
            cost_price=Decimal('40.00'),
            price_per_unit=Decimal('50.00'),
            quantity=Decimal('5.000')
        )

        res1 = self.client1.get('/api/products/')
        names1 = [p['name'] for p in res1.data]
        self.assertIn('User1 Soap', names1)
        self.assertNotIn('User2 Tea', names1)

        res2 = self.client2.get('/api/products/')
        names2 = [p['name'] for p in res2.data]
        self.assertIn('User2 Tea', names2)
        self.assertNotIn('User1 Soap', names2)
