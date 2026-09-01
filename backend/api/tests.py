"""
Budgeto API Tests.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from .models import Category, Account, Transaction, Budget, Goal

User = get_user_model()


class AuthTestCase(TestCase):
    """Test authentication endpoints."""

    def setUp(self):
        self.client = APIClient()
        self.register_url = '/api/auth/register/'
        self.login_url = '/api/auth/login/'
        self.me_url = '/api/auth/me/'

    def test_register_success(self):
        data = {
            'name': 'Test User',
            'email': 'test@budgeto.com',
            'password': 'testpass123',
        }
        response = self.client.post(self.register_url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('tokens', response.data)
        self.assertIn('user', response.data)
        self.assertEqual(response.data['user']['email'], 'test@budgeto.com')

    def test_register_duplicate_email(self):
        data = {
            'name': 'Test User',
            'email': 'test@budgeto.com',
            'password': 'testpass123',
        }
        self.client.post(self.register_url, data)
        response = self.client.post(self.register_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_success(self):
        # Register first
        self.client.post(self.register_url, {
            'name': 'Test', 'email': 'test@budgeto.com', 'password': 'testpass123',
        })
        # Login
        response = self.client.post(self.login_url, {
            'email': 'test@budgeto.com', 'password': 'testpass123',
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('tokens', response.data)

    def test_login_wrong_password(self):
        self.client.post(self.register_url, {
            'name': 'Test', 'email': 'test@budgeto.com', 'password': 'testpass123',
        })
        response = self.client.post(self.login_url, {
            'email': 'test@budgeto.com', 'password': 'wrongpass',
        })
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_me_authenticated(self):
        # Register and get token
        reg = self.client.post(self.register_url, {
            'name': 'Test', 'email': 'test@budgeto.com', 'password': 'testpass123',
        })
        token = reg.data['tokens']['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.get(self.me_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['email'], 'test@budgeto.com')

    def test_me_unauthenticated(self):
        response = self.client.get(self.me_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TransactionTestCase(TestCase):
    """Test transaction CRUD and analytics."""

    def setUp(self):
        self.client = APIClient()
        # Register and authenticate
        reg = self.client.post('/api/auth/register/', {
            'name': 'Test', 'email': 'test@budgeto.com', 'password': 'testpass123',
        })
        self.token = reg.data['tokens']['access']
        self.user = User.objects.get(email='test@budgeto.com')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

        # Seed categories
        Category.objects.create(id='cat_food', name='Alimentation', icon='food', color='0xFFFF6B35', type='expense')
        Category.objects.create(id='cat_salary', name='Salaire', icon='salary', color='0xFF2E7D32', type='income')

        # Create an account
        self.account = Account.objects.create(
            user=self.user, name='Cash', type='cash', balance=1000, color='0xFF000000'
        )

    def test_create_transaction(self):
        data = {
            'amount': '50.00',
            'type': 'expense',
            'category': 'cat_food',
            'account': str(self.account.id),
            'description': 'Courses',
            'date': '2026-08-29',
        }
        response = self.client.post('/api/transactions/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_list_transactions(self):
        Transaction.objects.create(
            user=self.user, amount=50, type='expense',
            category_id='cat_food', account=self.account,
            date='2026-08-29',
        )
        response = self.client.get('/api/transactions/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)

    def test_monthly_summary(self):
        Transaction.objects.create(
            user=self.user, amount=100, type='income',
            category_id='cat_salary', account=self.account,
            date='2026-08-15',
        )
        Transaction.objects.create(
            user=self.user, amount=30, type='expense',
            category_id='cat_food', account=self.account,
            date='2026-08-20',
        )
        response = self.client.get('/api/transactions/summary/?month=8&year=2026')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['income'], 100.0)
        self.assertEqual(response.data['expense'], 30.0)
        self.assertEqual(response.data['balance'], 70.0)


class GoalTestCase(TestCase):
    """Test goal CRUD and contributions."""

    def setUp(self):
        self.client = APIClient()
        reg = self.client.post('/api/auth/register/', {
            'name': 'Test', 'email': 'test@budgeto.com', 'password': 'testpass123',
        })
        self.token = reg.data['tokens']['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

    def test_create_goal(self):
        data = {
            'title': 'Vacances',
            'target_amount': '5000.00',
            'current_amount': '0.00',
        }
        response = self.client.post('/api/goals/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'Vacances')

    def test_contribute_to_goal(self):
        goal = Goal.objects.create(
            user=User.objects.get(email='test@budgeto.com'),
            title='Test', target_amount=1000, current_amount=0,
        )
        response = self.client.post(f'/api/goals/{goal.id}/contribute/', {'amount': '200.00'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['current_amount'], '200.00')
