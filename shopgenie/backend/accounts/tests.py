from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

User = get_user_model()

class AccountsAuthenticationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.register_url = '/api/auth/register/'
        self.login_url = '/api/auth/login/'
        self.refresh_url = '/api/auth/refresh/'

    def test_shopkeeper_registration_success(self):
        data = {
            'username': 'shopkeeper_raj',
            'email': 'raj@example.com',
            'shop_name': 'Raj Super Store',
            'password': 'SecurePassword123!',
            'password2': 'SecurePassword123!'
        }
        response = self.client.post(self.register_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('tokens', response.data)
        self.assertIn('access', response.data['tokens'])
        self.assertIn('refresh', response.data['tokens'])
        self.assertTrue(User.objects.filter(username='shopkeeper_raj').exists())

    def test_registration_password_mismatch(self):
        data = {
            'username': 'shopkeeper_raj',
            'email': 'raj@example.com',
            'password': 'Password123!',
            'password2': 'WrongPassword!'
        }
        response = self.client.post(self.register_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_jwt_login_success(self):
        User.objects.create_user(
            username='shopkeeper_priya',
            email='priya@example.com',
            password='PriyaPassword123!'
        )
        response = self.client.post(self.login_url, {
            'username': 'shopkeeper_priya',
            'password': 'PriyaPassword123!'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertIn('user', response.data)
