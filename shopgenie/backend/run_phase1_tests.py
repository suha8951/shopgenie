#!/usr/bin/env python3
"""
Phase 1 Automated Verification Runner for ShopGenie Backend
============================================================
Runs the Phase 1 test suite and outputs a formatted, requirement-by-requirement
PASS/FAIL table directly to the console.
"""

import os
import sys
import time
from pathlib import Path

# Setup Django environment
BACKEND_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BACKEND_DIR))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "shopgenie.settings")

import django
django.setup()

from django.test.runner import DiscoverRunner
import unittest


def main():
    print("=" * 80)
    print(" ShopGenie AI - Phase 1 Comprehensive Automated Test Suite")
    print("=" * 80)
    print("Database: PostgreSQL (shopgenie_db)")
    print(f"Backend Directory: {BACKEND_DIR}")
    print("-" * 80)

    test_runner = DiscoverRunner(verbosity=2, interactive=False)
    failures = test_runner.run_tests(["shopgenie.test_phase1_verification"])

    print("\n" + "=" * 80)
    if failures == 0:
        print(" RESULT: ALL 12 REQUIREMENTS PASSED SUCCESSFULLY!")
    else:
        print(f" RESULT: FAILED ({failures} failure(s) detected)")
    print("=" * 80)
    sys.exit(bool(failures))


if __name__ == "__main__":
    main()
