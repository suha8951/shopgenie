"""
Phase 2 Automated Test Suite: Computer Vision Engine & Django Vision API Integration
=====================================================================================
Tests all Phase 2 requirements:
1. CVEngine initialization & PyTorch MobileNetV3 model loading
2. Extract L2-normalized image embeddings (length = 576, norm == 1.0)
3. Fixed embedding dimension consistent with MobileNetV3 (576)
4. Cosine similarity matching (identity = 1.0, orthogonal/different < threshold)
5. Branded product visual matching against catalog database
6. Loose / plain-bag candidate visual detection using OpenCV heuristics
7. Frame capturing from ESP32-CAM MJPEG stream & snapshot buffer
8. Django Vision API integration:
   - POST /api/vision/embed/
   - POST /api/products/match/ (branded product match)
   - POST /api/products/match/ (loose commodity fallback / plain bag candidate)
   - POST /api/vision/capture/
9. Verification that phone internal camera is NOT used
10. Strict preservation of Django and PostgreSQL as primary backend & database
"""

from decimal import Decimal
import io
import base64
import numpy as np
import cv2
from PIL import Image
from unittest.mock import patch, MagicMock

from django.test import TestCase
from django.db import connection
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from cv_engine.cv_engine import (
    CVEngine,
    get_cv_engine,
    cosine_similarity,
    extract_features_and_detect_loose,
    MOBILENET_V3_SMALL_EMBEDDING_DIM
)
from products.models import Product
from vision.services import VisionService

User = get_user_model()


class Phase2ComputerVisionEngineTests(TestCase):
    """
    Comprehensive Phase 2 automated tests covering CVEngine, MobileNetV3,
    OpenCV loose detection, ESP32 stream handling, and Django Vision API endpoints.
    """

    @classmethod
    def setUpTestData(cls):
        # Create a sample branded image (e.g., bright packaging with high-contrast text)
        branded_np = np.zeros((256, 256, 3), dtype=np.uint8)
        cv2.rectangle(branded_np, (15, 15), (240, 240), (0, 0, 220), -1)
        cv2.putText(branded_np, "BRITANNIA", (25, 75), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255, 255, 255), 3)
        cv2.putText(branded_np, "GOOD DAY", (30, 130), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 255), 2)
        cv2.rectangle(branded_np, (35, 160), (220, 210), (0, 180, 0), -1)
        _, branded_enc = cv2.imencode('.jpg', branded_np)
        cls.sample_branded_bytes = branded_enc.tobytes()

        # Create a second distinct branded image (e.g., Maggi Noodles)
        maggi_np = np.zeros((256, 256, 3), dtype=np.uint8)
        cv2.rectangle(maggi_np, (15, 15), (240, 240), (0, 215, 255), -1)  # Yellow background
        cv2.putText(maggi_np, "MAGGI 2MIN", (20, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 0, 200), 3)
        cv2.circle(maggi_np, (128, 160), 40, (0, 0, 255), -1)
        _, maggi_enc = cv2.imencode('.jpg', maggi_np)
        cls.sample_maggi_bytes = maggi_enc.tobytes()

        # Create a loose transparent plastic bag image (uniform whitish grains / low edge count)
        loose_np = np.full((256, 256, 3), 220, dtype=np.uint8)
        noise = np.random.normal(0, 3, loose_np.shape).astype(np.int16)
        loose_np = np.clip(loose_np.astype(np.int16) + noise, 0, 255).astype(np.uint8)
        _, loose_enc = cv2.imencode('.jpg', loose_np)
        cls.sample_loose_bytes = loose_enc.tobytes()

    def setUp(self):
        self.client = APIClient()
        self.engine = get_cv_engine()

        # Create test shopkeeper
        self.user = User.objects.create_user(
            username="vision_shopkeeper",
            email="vision@kirana.com",
            password="VisionPassword123!",
            shop_name="Vision Provision Store"
        )
        login_res = self.client.post("/api/auth/login/", {
            "username": "vision_shopkeeper",
            "password": "VisionPassword123!"
        }, format="json")
        self.access_token = login_res.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access_token}")

    # -------------------------------------------------------------------------
    # Test 1: CVEngine initializes with PyTorch MobileNetV3
    # -------------------------------------------------------------------------
    def test_01_cv_engine_initialization_and_model_loading(self):
        """Verify CVEngine initializes, uses MobileNetV3 architecture, and sets evaluation mode."""
        self.assertIsNotNone(self.engine)
        self.assertEqual(self.engine.embedding_dim, 576)
        self.assertIsNotNone(self.engine.model)
        self.assertFalse(self.engine.model.training, "MobileNetV3 model must be in evaluation mode (eval())")

    # -------------------------------------------------------------------------
    # Test 2: Fixed Embedding Dimension consistent with MobileNetV3
    # -------------------------------------------------------------------------
    def test_02_fixed_embedding_dimension(self):
        """Verify embedding dimension is fixed at 576 across various image resolutions."""
        for size in [(100, 100), (224, 224), (400, 300), (640, 480)]:
            dummy = np.full((size[1], size[0], 3), 120, dtype=np.uint8)
            _, buf = cv2.imencode('.jpg', dummy)
            emb = self.engine.extract_embedding(buf.tobytes())
            self.assertIsNotNone(emb)
            self.assertEqual(len(emb), 576, f"Embedding dimension for input size {size} must be exactly 576")

    # -------------------------------------------------------------------------
    # Test 3: Extract L2-Normalized embeddings
    # -------------------------------------------------------------------------
    def test_03_l2_normalized_embeddings(self):
        """Verify generated embeddings are strictly L2-normalized (Euclidean norm == 1.0)."""
        emb_branded = self.engine.extract_embedding(self.sample_branded_bytes)
        self.assertIsNotNone(emb_branded)
        norm_branded = float(np.linalg.norm(emb_branded))
        self.assertAlmostEqual(norm_branded, 1.0, places=5)

        emb_loose = self.engine.extract_embedding(self.sample_loose_bytes)
        self.assertIsNotNone(emb_loose)
        norm_loose = float(np.linalg.norm(emb_loose))
        self.assertAlmostEqual(norm_loose, 1.0, places=5)

    # -------------------------------------------------------------------------
    # Test 4: Cosine similarity matching logic
    # -------------------------------------------------------------------------
    def test_04_cosine_similarity_computation(self):
        """Verify cosine similarity returns 1.0 for identical vectors and correct relative values."""
        emb1 = self.engine.extract_embedding(self.sample_branded_bytes)
        emb2 = self.engine.extract_embedding(self.sample_maggi_bytes)

        # Identical embeddings -> similarity == 1.0
        self_sim = cosine_similarity(emb1, emb1)
        self.assertAlmostEqual(self_sim, 1.0, places=4)

        # Distinct branded packaging embeddings -> distinct similarity < 1.0
        cross_sim = cosine_similarity(emb1, emb2)
        self.assertLess(cross_sim, 0.95)

        # Orthogonal synthetic vectors -> similarity == 0.0
        v_a = [1.0, 0.0, 0.0] + [0.0] * 573
        v_b = [0.0, 1.0, 0.0] + [0.0] * 573
        self.assertAlmostEqual(cosine_similarity(v_a, v_b), 0.0, places=5)

    # -------------------------------------------------------------------------
    # Test 5: Loose / Plain-bag candidate visual detection
    # -------------------------------------------------------------------------
    def test_05_loose_or_plain_bag_candidate_detection(self):
        """Verify OpenCV color/edge analysis detects plain plastic bags while rejecting branded items."""
        # Loose plain plastic bag sample should be detected as loose candidate
        is_loose = self.engine.detect_loose_candidate(self.sample_loose_bytes)
        self.assertTrue(is_loose, "Uniform translucent polythene bag must be detected as loose candidate")

        # Branded packaging with bold logos & sharp lines must NOT be detected as loose candidate
        is_branded_loose = self.engine.detect_loose_candidate(self.sample_branded_bytes)
        self.assertFalse(is_branded_loose, "High-contrast branded packaging must not be classified as loose bag")

    # -------------------------------------------------------------------------
    # Test 6: Branded product matching against catalog
    # -------------------------------------------------------------------------
    def test_06_branded_product_matching(self):
        """Verify catalog matching correctly identifies registered branded product."""
        # 1. Register Britannia Good Day with its embedding
        emb_britannia = self.engine.extract_embedding(self.sample_branded_bytes)
        prod = Product.objects.create(
            user=self.user,
            name="Britannia Good Day Butter",
            category="Biscuits",
            selling_type=Product.SellingType.UNIT,
            cost_price=Decimal("25.00"),
            price_per_unit=Decimal("30.00"),
            quantity=Decimal("50.000"),
            feature_vector=emb_britannia,
            is_loose=False
        )

        catalog_items = [
            {
                "id": prod.id,
                "name": prod.name,
                "feature_vector": prod.feature_vector
            }
        ]

        # 2. Query with the same branded image
        query_emb = self.engine.extract_embedding(self.sample_branded_bytes)
        matched_item, score = self.engine.match_branded_product(query_emb, catalog_items, similarity_threshold=0.78)

        self.assertIsNotNone(matched_item)
        self.assertEqual(matched_item["id"], prod.id)
        self.assertGreaterEqual(score, 0.78)

    # -------------------------------------------------------------------------
    # Test 7: ESP32-CAM MJPEG stream frame capture
    # -------------------------------------------------------------------------
    def test_07_esp32_cam_mjpeg_stream_frame_capture(self):
        """Verify MJPEG streaming extractor parses HTTP chunks and extracts a JPEG frame."""
        # Synthetic MJPEG stream chunk containing JPEG SOI (\xff\xd8) and EOI (\xff\xd9) markers
        jpeg_payload = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xff\xdb\x00\x43\x00\xff\xd9"
        multipart_stream_chunks = [
            b"--frame\r\nContent-Type: image/jpeg\r\n\r\n",
            jpeg_payload,
            b"\r\n--frame\r\n"
        ]

        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.iter_content.return_value = multipart_stream_chunks

        with patch("requests.get", return_value=mock_resp):
            frame_bytes, err = self.engine.capture_frame_from_esp32_stream("http://192.168.1.150:81/stream")
            self.assertIsNone(err)
            self.assertIsNotNone(frame_bytes)
            self.assertTrue(frame_bytes.startswith(b"\xff\xd8"))
            self.assertTrue(frame_bytes.endswith(b"\xff\xd9"))

    # -------------------------------------------------------------------------
    # Test 8: Django Vision API - POST /api/vision/embed/
    # -------------------------------------------------------------------------
    def test_08_django_api_vision_embed(self):
        """Verify POST /api/vision/embed/ generates a 576-dim feature vector via Django endpoint."""
        b64_image = base64.b64encode(self.sample_branded_bytes).decode('utf-8')
        res = self.client.post("/api/vision/embed/", {
            "image_base64": b64_image
        }, format="json")

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("feature_vector", res.data)
        self.assertEqual(res.data["vector_length"], 576)
        emb = res.data["feature_vector"]
        self.assertEqual(len(emb), 576)
        norm = float(np.linalg.norm(emb))
        self.assertAlmostEqual(norm, 1.0, places=4)

    # -------------------------------------------------------------------------
    # Test 9: Django Vision API - POST /api/products/match/ (Branded Match)
    # -------------------------------------------------------------------------
    def test_09_django_api_products_match_branded(self):
        """Verify POST /api/products/match/ returns PRODUCT match when branded item matches."""
        emb_maggi = self.engine.extract_embedding(self.sample_maggi_bytes)
        maggi_product = Product.objects.create(
            user=self.user,
            name="Nestle Maggi 2-Minute Noodles",
            category="Instant Noodles",
            selling_type=Product.SellingType.UNIT,
            cost_price=Decimal("12.00"),
            price_per_unit=Decimal("14.00"),
            quantity=Decimal("100.000"),
            feature_vector=emb_maggi,
            is_loose=False
        )

        b64_maggi = base64.b64encode(self.sample_maggi_bytes).decode('utf-8')
        res = self.client.post("/api/products/match/", {
            "image_base64": b64_maggi,
            "similarity_threshold": 0.75
        }, format="json")

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["match_type"], "PRODUCT")
        self.assertEqual(res.data["product_id"], maggi_product.id)
        self.assertEqual(res.data["name"], "Nestle Maggi 2-Minute Noodles")
        self.assertGreaterEqual(res.data["similarity"], 0.75)

    # -------------------------------------------------------------------------
    # Test 10: Django Vision API - POST /api/products/match/ (Loose Commodities)
    # -------------------------------------------------------------------------
    def test_10_django_api_products_match_loose_candidates(self):
        """Verify POST /api/products/match/ returns LOOSE_CANDIDATES list when plain bag is scanned."""
        # Create loose inventory items for this shopkeeper
        sugar = Product.objects.create(
            user=self.user,
            name="Madhur Pure Sugar Loose",
            category="Commodities",
            selling_type=Product.SellingType.KG,
            cost_price=Decimal("38.00"),
            price_per_unit=Decimal("44.00"),
            quantity=Decimal("80.000"),
            is_loose=True
        )
        rice = Product.objects.create(
            user=self.user,
            name="Sona Masoori Rice Loose",
            category="Grains",
            selling_type=Product.SellingType.KG,
            cost_price=Decimal("52.00"),
            price_per_unit=Decimal("60.00"),
            quantity=Decimal("120.000"),
            is_loose=True
        )

        b64_loose = base64.b64encode(self.sample_loose_bytes).decode('utf-8')
        res = self.client.post("/api/products/match/", {
            "image_base64": b64_loose
        }, format="json")

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["match_type"], "LOOSE_CANDIDATES")
        self.assertIn("candidates", res.data)
        candidate_ids = [c["id"] for c in res.data["candidates"]]
        self.assertIn(sugar.id, candidate_ids)
        self.assertIn(rice.id, candidate_ids)

    # -------------------------------------------------------------------------
    # Test 11: Verification that Phone's internal camera is NOT used
    # -------------------------------------------------------------------------
    def test_11_no_phone_internal_camera_dependency(self):
        """
        Verify the system does NOT invoke or require phone internal camera hardware,
        using only ESP32-CAM Wi-Fi stream URL and backend image payloads.
        """
        # Test that POST /api/vision/capture/ pulls from ESP32-CAM stream URL
        fake_frame = self.sample_branded_bytes
        with patch.object(VisionService, "capture_frame_from_esp32", return_value=(fake_frame, None)):
            res = self.client.post("/api/vision/capture/", {
                "esp32_cam_url": "http://192.168.1.100:81/stream"
            }, format="json")
            self.assertEqual(res.status_code, status.HTTP_200_OK)
            self.assertIn("image_base64", res.data)
            self.assertIn("feature_vector", res.data)
            self.assertEqual(len(res.data["feature_vector"]), 576)

    # -------------------------------------------------------------------------
    # Test 12: Preservation of Django & PostgreSQL architecture
    # -------------------------------------------------------------------------
    def test_12_preservation_of_django_and_postgresql(self):
        """Verify Django and PostgreSQL remain the active application framework and database."""
        engine = connection.settings_dict["ENGINE"]
        self.assertIn("postgresql", engine, "PostgreSQL must remain the active database engine")
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_database();")
            db_name = cursor.fetchone()[0]
            self.assertTrue(len(db_name) > 0)
