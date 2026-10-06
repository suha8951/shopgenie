import io
import sys
import requests
import numpy as np
from pathlib import Path
from decimal import Decimal
from typing import Tuple, Optional, Dict, Any, List
from django.conf import settings
from products.models import Product

class VisionService:
    """
    Connects Django with the ESP32-CAM Wi-Fi stream and the Computer Vision Engine.
    Handles frame capturing, embedding generation, and cosine similarity lookup.
    """

    @staticmethod
    def capture_frame_from_esp32(stream_url: str, timeout_sec: int = 5) -> Tuple[Optional[bytes], Optional[str]]:
        """
        Captures a single JPEG frame from an external ESP32-CAM.
        Supports both:
        1. Snapshot endpoint: http://<ip>/capture
        2. MJPEG video stream: http://<ip>:81/stream
        """
        if not stream_url:
            return None, "ESP32-CAM URL not provided."

        try:
            # 1. If URL points directly to snapshot or non-stream endpoint, perform GET
            if not stream_url.endswith('/stream'):
                resp = requests.get(stream_url, timeout=timeout_sec)
                if resp.status_code == 200 and len(resp.content) > 100:
                    return resp.content, None

            # 2. Extract single frame from MJPEG stream
            response = requests.get(stream_url, stream=True, timeout=timeout_sec)
            if response.status_code != 200:
                return None, f"ESP32-CAM returned status code {response.status_code}"

            buffer = bytes()
            for chunk in response.iter_content(chunk_size=4096):
                buffer += chunk
                a = buffer.find(b'\xff\xd8')  # JPEG start marker
                b = buffer.find(b'\xff\xd9')  # JPEG end marker
                if a != -1 and b != -1:
                    jpg_data = buffer[a:b+2]
                    return jpg_data, None

            return None, "No complete JPEG frame could be read from the MJPEG stream."

        except requests.exceptions.Timeout:
            return None, f"Timeout connecting to ESP32-CAM at {stream_url}."
        except requests.exceptions.RequestException as e:
            return None, f"Network error communicating with ESP32-CAM: {str(e)}"
        except Exception as e:
            return None, f"Unexpected error during frame capture: {str(e)}"

    @classmethod
    def get_embedding_from_cv_engine(cls, image_bytes: bytes) -> Tuple[Optional[List[float]], bool]:
        """
        Invokes the MobileNetV3 CV Engine to extract an L2-normalized embedding
        and determine whether the frame represents a loose / plain bag.
        """
        # Ensure cv_engine is in Python path (check both root and shopgenie subdirs)
        possible_cv_dirs = [
            str(settings.BASE_DIR.parent / 'cv_engine'),
            str(settings.BASE_DIR.parent.parent / 'cv_engine'),
            str(settings.BASE_DIR.parent),
        ]
        for p in possible_cv_dirs:
            if p not in sys.path and Path(p).exists():
                sys.path.insert(0, p)

        try:
            from cv_engine import extract_features_and_detect_loose
            embedding, is_loose = extract_features_and_detect_loose(image_bytes)
            return embedding, is_loose
        except ImportError as e:
            return None, False
        except Exception as e:
            return None, False

    @classmethod
    def cosine_similarity(cls, vec_a: List[float], vec_b: List[float]) -> float:
        """Calculates cosine similarity between two float vectors."""
        if not vec_a or not vec_b or len(vec_a) != len(vec_b):
            return 0.0
        a = np.array(vec_a, dtype=np.float32)
        b = np.array(vec_b, dtype=np.float32)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        if norm_a == 0 or norm_b == 0:
            return 0.0
        return float(np.dot(a, b) / (norm_a * norm_b))

    @classmethod
    def match_product(
        cls,
        user,
        image_bytes: bytes,
        similarity_threshold: float = 0.78
    ) -> Dict[str, Any]:
        """
        Matches a captured frame against the authenticated shopkeeper's products only.
        
        Strict Isolation:
        Only checks Product.objects.filter(user=user). Never exposes another user's catalog.
        
        Output rules:
        - If the item is detected as plain-bag/loose or no branded item meets the threshold:
          Returns LOOSE_CANDIDATES from the shopkeeper's loose inventory (Sugar, Rice, etc.).
        - If a branded product matches with >= similarity_threshold:
          Returns PRODUCT match with product details.
        """
        user_products = Product.objects.filter(user=user)
        loose_products = user_products.filter(is_loose=True)

        embedding, is_loose_visual = cls.get_embedding_from_cv_engine(image_bytes)

        # If visual feature extraction detects a plain transparent/white grocery bag:
        if is_loose_visual:
            return cls._build_loose_candidates_response(loose_products)

        # If we have an embedding, perform cosine similarity against branded products
        if embedding:
            best_match: Optional[Product] = None
            best_similarity: float = -1.0

            for prod in user_products.filter(is_loose=False):
                if prod.feature_vector:
                    sim = cls.cosine_similarity(embedding, prod.feature_vector)
                    if sim > best_similarity:
                        best_similarity = sim
                        best_match = prod

            if best_match and best_similarity >= similarity_threshold:
                return {
                    "match_type": "PRODUCT",
                    "product_id": best_match.id,
                    "name": best_match.name,
                    "category": best_match.category,
                    "selling_type": best_match.selling_type,
                    "cost_price": float(best_match.cost_price),
                    "price_per_unit": float(best_match.price_per_unit),
                    "quantity": float(best_match.quantity),
                    "formatted_quantity": best_match.formatted_quantity,
                    "similarity": round(best_similarity, 3)
                }

        # If no strong branded match is found, return loose candidates as fallback
        return cls._build_loose_candidates_response(loose_products)

    @staticmethod
    def _build_loose_candidates_response(loose_products) -> Dict[str, Any]:
        candidates = []
        for p in loose_products:
            candidates.append({
                "id": p.id,
                "name": p.name,
                "category": p.category,
                "selling_type": p.selling_type,
                "price_per_unit": float(p.price_per_unit),
                "cost_price": float(p.cost_price),
                "quantity": float(p.quantity),
                "formatted_quantity": p.formatted_quantity
            })

        return {
            "match_type": "LOOSE_CANDIDATES",
            "message": "Plain-bag or loose commodity detected. Please select candidate item and enter weight.",
            "candidates": candidates
        }
