#!/usr/bin/env python3
"""
Automated runner for ShopGenie Phase 2: Computer Vision Engine Verification.
Executes all 12 Phase 2 test specifications with full verbose reporting.
"""

import os
import sys
import subprocess

def run_tests():
    print("=" * 80)
    print(" SHOPGENIE - PHASE 2: COMPUTER VISION ENGINE VERIFICATION SUITE")
    print("=" * 80)
    print("Testing against requirements:")
    print(" 1. Create cv_engine/cv_engine.py with MobileNetV3 & OpenCV")
    print(" 2. Fixed embedding dimension consistent with model (576)")
    print(" 3. Extract L2-normalized image embeddings (Euclidean norm == 1.0)")
    print(" 4. Implement cosine similarity matching")
    print(" 5. Support loose / plain-bag candidate visual detection")
    print(" 6. Support branded product matching against registered catalog")
    print(" 7. Support capturing frames from ESP32-CAM MJPEG stream")
    print(" 8. Integrate with Django Vision API: POST /api/vision/embed/")
    print(" 9. Integrate with Django Vision API: POST /api/products/match/ (Branded)")
    print(" 10. Integrate with Django Vision API: POST /api/products/match/ (Loose Candidates)")
    print(" 11. Strict restriction: No phone internal camera used (Wi-Fi ESP32-CAM only)")
    print(" 12. Strict restriction: Preservation of Django & PostgreSQL architecture")
    print("=" * 80)

    # Set up environment
    env = os.environ.copy()
    env["PYTHONWARNINGS"] = "ignore"

    cmd = [
        sys.executable,
        "shopgenie/backend/manage.py",
        "test",
        "shopgenie.test_phase2_verification",
        "-v", "2"
    ]

    result = subprocess.run(cmd, env=env, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        # Filter benign NNPACK warnings for cleaner output
        clean_err = "\n".join([line for line in result.stderr.splitlines() if "NNPACK" not in line])
        if clean_err.strip():
            print(clean_err)

    if result.returncode == 0:
        print("\n" + "=" * 80)
        print(" ALL PHASE 2 REQUIREMENTS PASSED SUCCESSFULLY!")
        print("=" * 80)
    else:
        print("\n" + "=" * 80)
        print(" TESTS FAILED. EXIT CODE:", result.returncode)
        print("=" * 80)

    return result.returncode

if __name__ == "__main__":
    sys.exit(run_tests())
