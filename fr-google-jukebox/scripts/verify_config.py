#!/usr/bin/env python3
"""
Test script to verify config loading in different modes.

This script demonstrates how the settings work in local vs production mode.
"""

import os
import sys

# Test 1: Check if .env file would be read
print("=" * 70)
print("CONFIG LOADING TEST")
print("=" * 70)

print("\n1. Checking environment mode detection...")
env_mode = os.getenv("ENV", "local")
print(f"   Current ENV mode: {env_mode}")

# Test 2: Show what get_secret does without actually loading it
print("\n2. How get_secret() works:")
print(f"   - If ENV != 'production': reads from environment variables (.env file)")
print(f"   - If ENV == 'production': reads from Google Secret Manager")

# Test 3: Verify .env.example exists
print("\n3. Checking .env files...")
if os.path.exists(".env"):
    print("   ✓ .env file found (loaded at runtime)")
else:
    print("   ✗ .env file NOT found (run: cp .env.example .env)")

if os.path.exists(".env.example"):
    print("   ✓ .env.example found (template for local setup)")
else:
    print("   ✗ .env.example NOT found")

# Test 4: Show required variables in local mode
print("\n4. Required environment variables for local mode:")
required_local = [
    "ENV",
    "GEMINI_API_KEY",
    "REPLICATE_API_TOKEN",
    "GCLOUD_PROJECT_ID",
    "GCLOUD_PROJECT_NUMBER",
    "GCLOUD_MUSIC_BUCKET",
]
for var in required_local:
    value = os.getenv(var)
    status = "✓" if value else "✗"
    display_value = value[:20] + "..." if value and len(value) > 20 else value or "(not set)"
    print(f"   {status} {var}: {display_value}")

# Test 5: Show production mode requirements
print("\n5. Required variables for production mode (ENV=production):")
print("   - Must have: GCLOUD_PROJECT_NUMBER (for Secret Manager access)")
print("   - Must have: GCLOUD_PROJECT_ID, GCLOUD_MUSIC_BUCKET")
print("   - Secrets auto-fetched: GEMINI_API_KEY, REPLICATE_API_TOKEN, GOOGLE_APP_PASSWORD")

print("\n" + "=" * 70)
print("NEXT STEPS:")
print("=" * 70)
if not os.path.exists(".env"):
    print("1. Copy template: cp .env.example .env")
    print("2. Edit .env with your local credentials")
else:
    print("✓ .env file ready. Run: uvicorn app.main:app --reload")

print("\n" + "=" * 70)
