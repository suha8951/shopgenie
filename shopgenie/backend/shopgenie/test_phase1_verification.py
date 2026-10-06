"""
Phase 1 Automated Test Suite for ShopGenie Backend
===================================================
Covers all 12 Phase 1 requirements:
1. Django starts successfully.
2. PostgreSQL connection works.
3. CustomUser model and migrations work.
4. POST /api/auth/register/ creates a user successfully.
5. POST /api/auth/login/ returns JWT access and refresh tokens.
6. POST /api/auth/refresh/ returns a new access token.
7. JWT access tokens authenticate protected requests.
8. Protected endpoints reject unauthenticated requests with HTTP 401.
9. Authenticated requests using Bearer <access_token> work.
10. Product registration saves the product under the authenticated user.
11. User A cannot access User B's products.
12. Checkout safely decrements stock using database transactions and prevents invalid stock updates.
"""

from decimal import Decimal
from django.test import TestCase, TransactionTestCase
from django.core.management import call_command
from django.db import connection, transaction
from django.db.migrations.executor import MigrationExecutor
from django.contrib.auth import get_user_model
from django.apps import apps
from rest_framework.test import APIClient
from rest_framework import status
from products.models import Product
from billing.models import Invoice, InvoiceItem

User = get_user_model()


class Phase1ComprehensiveVerificationTests(TestCase):
    """
    Automated test suite systematically verifying all 12 Phase 1 backend requirements.
    """

    def setUp(self):
        self.client = APIClient()

        # Create two distinct test users for tenant isolation and authentication tests
        self.user_a_password = "SecurePasswordA123!"
        self.user_a = User.objects.create_user(
            username="shopkeeper_alpha",
            email="alpha@retailstore.com",
            password=self.user_a_password,
            shop_name="Alpha Provision Store"
        )

        self.user_b_password = "SecurePasswordB456!"
        self.user_b = User.objects.create_user(
            username="shopkeeper_beta",
            email="beta@retailstore.com",
            password=self.user_b_password,
            shop_name="Beta Groceries"
        )

        # Obtain JWT tokens for User A
        login_res_a = self.client.post("/api/auth/login/", {
            "username": "shopkeeper_alpha",
            "password": self.user_a_password
        }, format="json")
        self.token_a_access = login_res_a.data["access"]
        self.token_a_refresh = login_res_a.data["refresh"]

        # Obtain JWT tokens for User B
        login_res_b = self.client.post("/api/auth/login/", {
            "username": "shopkeeper_beta",
            "password": self.user_b_password
        }, format="json")
        self.token_b_access = login_res_b.data["access"]
        self.token_b_refresh = login_res_b.data["refresh"]

    # -------------------------------------------------------------------------
    # Requirement 1: Django starts successfully
    # -------------------------------------------------------------------------
    def test_01_django_starts_successfully(self):
        """
        Req 1: Verify Django boots, settings are valid, installed apps are loaded,
        and system checks complete without any errors.
        """
        # 1. System checks pass cleanly with zero issues
        try:
            call_command("check")
            check_passed = True
        except Exception as e:
            check_passed = False
            self.fail(f"Django system check failed: {e}")
        self.assertTrue(check_passed)

        # 2. Key apps are loaded and configured in application registry
        required_apps = ["accounts", "products", "billing", "vision", "rest_framework", "rest_framework_simplejwt"]
        for app_label in required_apps:
            self.assertTrue(apps.is_installed(app_label), f"App '{app_label}' is not registered in INSTALLED_APPS")

    # -------------------------------------------------------------------------
    # Requirement 2: PostgreSQL connection works
    # -------------------------------------------------------------------------
    def test_02_postgresql_connection_works(self):
        """
        Req 2: Verify active connection to PostgreSQL database and ability
        to execute SQL queries.
        """
        # Verify backend engine is PostgreSQL
        engine = connection.settings_dict["ENGINE"]
        self.assertIn("postgresql", engine, f"Expected PostgreSQL backend engine, got: {engine}")

        # Execute raw SQL query to test connectivity
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1 AS alive, current_database(), version();")
            row = cursor.fetchone()
            self.assertIsNotNone(row)
            self.assertEqual(row[0], 1)
            db_name = row[1]
            pg_version = row[2]
            self.assertTrue(len(db_name) > 0)
            self.assertIn("PostgreSQL", pg_version)

    # -------------------------------------------------------------------------
    # Requirement 3: CustomUser model and migrations work
    # -------------------------------------------------------------------------
    def test_03_custom_user_model_and_migrations_work(self):
        """
        Req 3: Verify CustomUser model is active, fields function properly,
        passwords are safely hashed, and all migrations are applied.
        """
        # Verify active user model is CustomUser
        self.assertEqual(User.__name__, "CustomUser")
        self.assertEqual(User._meta.db_table, "shopgenie_users")

        # Test creating a new user through CustomUser manager
        new_user = User.objects.create_user(
            username="test_custom_user",
            email="custom@example.com",
            password="StrongPassword789!",
            shop_name="Custom Kirana Shop"
        )
        self.assertEqual(new_user.shop_name, "Custom Kirana Shop")
        self.assertTrue(new_user.check_password("StrongPassword789!"))
        self.assertFalse(new_user.check_password("WrongPassword"))
        # Password must not be plaintext
        self.assertNotEqual(new_user.password, "StrongPassword789!")

        # Verify no unapplied migrations exist
        executor = MigrationExecutor(connection)
        targets = executor.loader.graph.leaf_nodes()
        plan = executor.migration_plan(targets)
        self.assertEqual(len(plan), 0, f"Unapplied migrations detected: {plan}")

    # -------------------------------------------------------------------------
    # Requirement 4: POST /api/auth/register/ creates a user successfully
    # -------------------------------------------------------------------------
    def test_04_post_api_auth_register_creates_user_successfully(self):
        """
        Req 4: Verify POST /api/auth/register/ registers a shopkeeper,
        returns HTTP 201 with user data and tokens, and persists user in DB.
        """
        register_payload = {
            "username": "new_shopkeeper_vikram",
            "email": "vikram@kirana.com",
            "shop_name": "Vikram General Store",
            "password": "VikramSecurePass123!",
            "password2": "VikramSecurePass123!"
        }
        res = self.client.post("/api/auth/register/", register_payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn("user", res.data)
        self.assertEqual(res.data["user"]["username"], "new_shopkeeper_vikram")
        self.assertEqual(res.data["user"]["email"], "vikram@kirana.com")
        self.assertEqual(res.data["user"]["shop_name"], "Vikram General Store")
        self.assertIn("tokens", res.data)
        self.assertIn("access", res.data["tokens"])
        self.assertIn("refresh", res.data["tokens"])

        # Check in PostgreSQL database
        persisted = User.objects.filter(username="new_shopkeeper_vikram").first()
        self.assertIsNotNone(persisted)
        self.assertTrue(persisted.check_password("VikramSecurePass123!"))

    # -------------------------------------------------------------------------
    # Requirement 5: POST /api/auth/login/ returns JWT access and refresh tokens
    # -------------------------------------------------------------------------
    def test_05_post_api_auth_login_returns_jwt_tokens(self):
        """
        Req 5: Verify POST /api/auth/login/ authenticates valid credentials
        and returns both JWT access and refresh tokens along with user metadata.
        """
        login_payload = {
            "username": "shopkeeper_alpha",
            "password": self.user_a_password
        }
        res = self.client.post("/api/auth/login/", login_payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("access", res.data)
        self.assertIn("refresh", res.data)
        self.assertTrue(len(res.data["access"]) > 20)
        self.assertTrue(len(res.data["refresh"]) > 20)
        self.assertIn("user", res.data)
        self.assertEqual(res.data["user"]["username"], "shopkeeper_alpha")

        # Wrong password must fail with 401
        res_invalid = self.client.post("/api/auth/login/", {
            "username": "shopkeeper_alpha",
            "password": "WrongPassword!"
        }, format="json")
        self.assertEqual(res_invalid.status_code, status.HTTP_401_UNAUTHORIZED)

    # -------------------------------------------------------------------------
    # Requirement 6: POST /api/auth/refresh/ returns a new access token
    # -------------------------------------------------------------------------
    def test_06_post_api_auth_refresh_returns_new_access_token(self):
        """
        Req 6: Verify POST /api/auth/refresh/ takes a valid refresh token
        and returns a newly generated access token.
        """
        refresh_payload = {
            "refresh": self.token_a_refresh
        }
        res = self.client.post("/api/auth/refresh/", refresh_payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("access", res.data)
        new_access_token = res.data["access"]
        self.assertTrue(len(new_access_token) > 20)

        # Invalid or corrupted refresh token must fail with 401
        res_bad = self.client.post("/api/auth/refresh/", {"refresh": "invalid.jwt.token"}, format="json")
        self.assertEqual(res_bad.status_code, status.HTTP_401_UNAUTHORIZED)

    # -------------------------------------------------------------------------
    # Requirement 7: JWT access tokens authenticate protected requests
    # -------------------------------------------------------------------------
    def test_07_jwt_access_tokens_authenticate_protected_requests(self):
        """
        Req 7: Verify JWT access token authenticates the user on protected endpoints
        and resolves the identity of the authenticated user correctly.
        """
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.token_a_access}")
        res = self.client.get("/api/auth/me/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["username"], "shopkeeper_alpha")
        self.assertEqual(res.data["email"], "alpha@retailstore.com")
        self.assertEqual(res.data["shop_name"], "Alpha Provision Store")

        # Switch to User B token
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.token_b_access}")
        res_b = self.client.get("/api/auth/me/")
        self.assertEqual(res_b.status_code, status.HTTP_200_OK)
        self.assertEqual(res_b.data["username"], "shopkeeper_beta")

    # -------------------------------------------------------------------------
    # Requirement 8: Protected endpoints reject unauthenticated requests (HTTP 401)
    # -------------------------------------------------------------------------
    def test_08_protected_endpoints_reject_unauthenticated_requests_with_401(self):
        """
        Req 8: Verify all protected endpoints reject requests without auth credentials
        with HTTP 401 Unauthorized.
        """
        # Ensure client has no credentials
        self.client.credentials()

        protected_endpoints = [
            ("GET", "/api/auth/me/", None),
            ("GET", "/api/products/", None),
            ("POST", "/api/products/register/", {"name": "Test Item"}),
            ("POST", "/api/checkout/accept/", {"product_id": 1, "quantity": 1}),
            ("GET", "/api/checkout/invoices/", None),
            ("GET", "/api/checkout/analytics/", None),
        ]

        for method, url, payload in protected_endpoints:
            if method == "GET":
                res = self.client.get(url)
            else:
                res = self.client.post(url, payload, format="json")
            self.assertEqual(
                res.status_code,
                status.HTTP_401_UNAUTHORIZED,
                f"Endpoint {method} {url} returned {res.status_code}, expected 401 Unauthorized"
            )

    # -------------------------------------------------------------------------
    # Requirement 9: Authenticated requests using Bearer <access_token> work
    # -------------------------------------------------------------------------
    def test_09_authenticated_requests_using_bearer_token_work(self):
        """
        Req 9: Verify requests explicitly using standard Bearer <access_token> headers
        are authorized to perform inventory and account operations.
        """
        client = APIClient()
        # Set Authorization header with Bearer prefix
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.token_a_access}")

        # 1. Access profile
        res_profile = client.get("/api/auth/me/")
        self.assertEqual(res_profile.status_code, status.HTTP_200_OK)

        # 2. Access inventory list
        res_products = client.get("/api/products/")
        self.assertEqual(res_products.status_code, status.HTTP_200_OK)
        self.assertIsInstance(res_products.data, list)

        # 3. Access analytics
        res_analytics = client.get("/api/checkout/analytics/")
        self.assertEqual(res_analytics.status_code, status.HTTP_200_OK)
        self.assertIn("total_sales", res_analytics.data)

        # 4. Malformed Bearer header returns 401
        client.credentials(HTTP_AUTHORIZATION="Bearer malformed_token_string")
        res_malformed = client.get("/api/products/")
        self.assertEqual(res_malformed.status_code, status.HTTP_401_UNAUTHORIZED)

    # -------------------------------------------------------------------------
    # Requirement 10: Product registration saves product under authenticated user
    # -------------------------------------------------------------------------
    def test_10_product_registration_saves_under_authenticated_user(self):
        """
        Req 10: Verify POST /api/products/register/ saves the item under the
        authenticated user in PostgreSQL, populating all attributes accurately.
        """
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.token_a_access}")

        # 1. Register UNIT product
        unit_payload = {
            "name": "Tata Tea Gold 250g",
            "category": "Beverages",
            "selling_type": "UNIT",
            "cost_price": "120.00",
            "price_per_unit": "145.00",
            "quantity": "25.000",
            "is_loose": False
        }
        res_unit = client.post("/api/products/register/", unit_payload, format="json")
        self.assertEqual(res_unit.status_code, status.HTTP_201_CREATED)
        unit_product_id = res_unit.data["id"]

        # Verify in database that owner is User A
        unit_product = Product.objects.get(id=unit_product_id)
        self.assertEqual(unit_product.user, self.user_a)
        self.assertEqual(unit_product.name, "Tata Tea Gold 250g")
        self.assertEqual(unit_product.selling_type, Product.SellingType.UNIT)
        self.assertEqual(unit_product.price_per_unit, Decimal("145.00"))
        self.assertEqual(unit_product.quantity, Decimal("25.000"))

        # 2. Register KG loose product
        kg_payload = {
            "name": "Toor Dal Premium Loose",
            "category": "Pulses",
            "selling_type": "KG",
            "cost_price": "110.00",
            "price_per_unit": "135.50",
            "quantity": "50.500",
            "is_loose": True
        }
        res_kg = client.post("/api/products/register/", kg_payload, format="json")
        self.assertEqual(res_kg.status_code, status.HTTP_201_CREATED)
        kg_product_id = res_kg.data["id"]

        kg_product = Product.objects.get(id=kg_product_id)
        self.assertEqual(kg_product.user, self.user_a)
        self.assertEqual(kg_product.selling_type, Product.SellingType.KG)
        self.assertTrue(kg_product.is_loose)
        self.assertEqual(kg_product.quantity, Decimal("50.500"))

    # -------------------------------------------------------------------------
    # Requirement 11: User A cannot access User B's products
    # -------------------------------------------------------------------------
    def test_11_user_a_cannot_access_user_b_products(self):
        """
        Req 11: Verify strict multi-tenant isolation:
        - User A cannot see User B's products in inventory list
        - User A cannot retrieve User B's product by direct ID (HTTP 404)
        - User A cannot edit or delete User B's product
        - User A cannot bill or checkout User B's product
        """
        # User A product
        prod_a = Product.objects.create(
            user=self.user_a,
            name="Alpha Exclusive Biscuit",
            category="Snacks",
            selling_type="UNIT",
            cost_price=Decimal("10.00"),
            price_per_unit=Decimal("15.00"),
            quantity=Decimal("30.000")
        )
        # User B product
        prod_b = Product.objects.create(
            user=self.user_b,
            name="Beta Exclusive Coffee",
            category="Beverages",
            selling_type="UNIT",
            cost_price=Decimal("80.00"),
            price_per_unit=Decimal("100.00"),
            quantity=Decimal("15.000")
        )

        client_a = APIClient()
        client_a.credentials(HTTP_AUTHORIZATION=f"Bearer {self.token_a_access}")

        # 1. Product list check: User A must see only their product
        res_list = client_a.get("/api/products/")
        self.assertEqual(res_list.status_code, status.HTTP_200_OK)
        retrieved_ids = [p["id"] for p in res_list.data]
        self.assertIn(prod_a.id, retrieved_ids)
        self.assertNotIn(prod_b.id, retrieved_ids)

        # 2. Direct detail access: User A accessing User B's product ID must return 404
        res_detail = client_a.get(f"/api/products/{prod_b.id}/")
        self.assertEqual(res_detail.status_code, status.HTTP_404_NOT_FOUND)

        # 3. Direct modification: User A attempting to update User B's product must return 404
        res_update = client_a.patch(f"/api/products/{prod_b.id}/", {"name": "Hacked Coffee"}, format="json")
        self.assertEqual(res_update.status_code, status.HTTP_404_NOT_FOUND)
        prod_b.refresh_from_db()
        self.assertEqual(prod_b.name, "Beta Exclusive Coffee")  # Unchanged

        # 4. Direct deletion: User A attempting to delete User B's product must return 404
        res_delete = client_a.delete(f"/api/products/{prod_b.id}/")
        self.assertEqual(res_delete.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(Product.objects.filter(id=prod_b.id).exists())

        # 5. Checkout isolation: User A attempting to checkout User B's product must be rejected
        res_checkout = client_a.post("/api/checkout/accept/", {
            "product_id": prod_b.id,
            "quantity": "1.000"
        }, format="json")
        self.assertEqual(res_checkout.status_code, status.HTTP_404_NOT_FOUND)

    # -------------------------------------------------------------------------
    # Requirement 12: Checkout safely decrements stock and prevents invalid updates
    # -------------------------------------------------------------------------
    def test_12_checkout_safely_decrements_stock_using_database_transactions(self):
        """
        Req 12: Verify database transactions and atomic decrement during checkout:
        - Valid UNIT checkout decrements stock accurately
        - Valid KG checkout decrements fractional stock accurately
        - Over-checkout (quantity > stock) is rejected with 409 Conflict
        - Over-checkout transaction rolls back without changing stock
        - Invalid non-integer quantity for UNIT items is rejected with 400
        - Correct Invoice and InvoiceItem records are generated with server-computed prices
        """
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.token_a_access}")

        # Unit Product: Initial stock = 10 units @ 20.00
        unit_prod = Product.objects.create(
            user=self.user_a,
            name="Britannia Bread 400g",
            category="Bakery",
            selling_type="UNIT",
            cost_price=Decimal("15.00"),
            price_per_unit=Decimal("20.00"),
            quantity=Decimal("10.000")
        )

        # KG Product: Initial stock = 20.000 kg @ 40.00
        kg_prod = Product.objects.create(
            user=self.user_a,
            name="Aashirvaad Atta",
            category="Flour",
            selling_type="KG",
            cost_price=Decimal("32.00"),
            price_per_unit=Decimal("40.00"),
            quantity=Decimal("20.000"),
            is_loose=True
        )

        # Test 12.1: Valid UNIT checkout of 3 units
        res1 = client.post("/api/checkout/accept/", {
            "product_id": unit_prod.id,
            "quantity": "3.000"
        }, format="json")
        self.assertEqual(res1.status_code, status.HTTP_200_OK)

        # Check stock decremented: 10 - 3 = 7
        unit_prod.refresh_from_db()
        self.assertEqual(unit_prod.quantity, Decimal("7.000"))

        invoice_id = res1.data["invoice"]["id"]
        inv1 = Invoice.objects.get(id=invoice_id)
        self.assertEqual(inv1.total_amount, Decimal("60.00"))  # 3 * 20.00

        # Test 12.2: Valid KG checkout with fractional quantity (2.750 kg)
        res2 = client.post("/api/checkout/accept/", {
            "product_id": kg_prod.id,
            "quantity": "2.750",
            "invoice_id": invoice_id
        }, format="json")
        self.assertEqual(res2.status_code, status.HTTP_200_OK)

        # Check stock decremented: 20 - 2.75 = 17.25
        kg_prod.refresh_from_db()
        self.assertEqual(kg_prod.quantity, Decimal("17.250"))

        # Check aggregate invoice total: 60.00 + (2.75 * 40.00 = 110.00) = 170.00
        inv1.refresh_from_db()
        self.assertEqual(inv1.total_amount, Decimal("170.00"))

        # Test 12.3: Over-checkout prevention (Insufficient stock)
        # Attempt to checkout 25.000 kg when only 17.250 kg available
        res_over = client.post("/api/checkout/accept/", {
            "product_id": kg_prod.id,
            "quantity": "25.000"
        }, format="json")
        self.assertEqual(res_over.status_code, status.HTTP_409_CONFLICT)
        self.assertIn("Insufficient stock", res_over.data["error"])

        # Transaction safety check: stock must remain exactly 17.250 kg
        kg_prod.refresh_from_db()
        self.assertEqual(kg_prod.quantity, Decimal("17.250"))

        # Test 12.4: Fractional quantity on UNIT item must be rejected
        res_fractional_unit = client.post("/api/checkout/accept/", {
            "product_id": unit_prod.id,
            "quantity": "1.500"
        }, format="json")
        self.assertEqual(res_fractional_unit.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("integer quantity", res_fractional_unit.data["error"])

        # Stock must remain unchanged
        unit_prod.refresh_from_db()
        self.assertEqual(unit_prod.quantity, Decimal("7.000"))
