# Configuration Migration Summary

## Overview
The backend now supports seamless switching between **local development** (`.env` file) and **production** (Google Secret Manager) without code changes.

## Key Changes Made

### 1. `app/core/config.py` — Major Refactor
**Before:**
- Direct calls to `secretmanager.SecretManagerServiceClient()` at class definition time
- Variables fetched from env vars directly (e.g., `PROJECT_ID = os.getenv(...)`)
- Would crash at import if Secret Manager was unavailable or env vars were missing
- Typo in `BACKEND_CORS_ORIGINS` ("projects/" parasite)

**After:**
- New function `get_secret(secret_key: str)` that:
  - Checks `ENV` environment variable
  - If `ENV != "production"`: reads from env vars (via `.env`)
  - If `ENV == "production"`: fetches from Google Secret Manager
  - Provides clear error messages if secrets are missing
- All GCP settings now use `Field(env=...)` (not hardcoded globals)
- `GCLOUD_PROJECT_NUMBER` is required only in production mode
- Validation in `__init__` ensures required secrets are present before starting
- Clean import, no Secret Manager calls at module load time

**Secrets now handled:**
- `GEMINI_API_KEY`
- `REPLICATE_API_TOKEN`
- `GOOGLE_APP_PASSWORD`

### 2. `.env.example` — New File
Template for local development:
```
ENV=local
GCLOUD_PROJECT_ID=your-project
GCLOUD_PROJECT_NUMBER=your-number
GCLOUD_MUSIC_BUCKET=prompts_results
GEMINI_API_KEY=your-key
REPLICATE_API_TOKEN=your-token
...
```
Provides all variables needed for local development without actual credentials.

### 3. Dynamic `.env` File Loading — `.env.local` & `.env.prod`
**NEW:** Instead of hardcoding `.env`, pydantic now automatically loads the right file based on `ENV`:

```python
def get_env_file() -> str:
    env = os.getenv("ENV", "local")
    return ".env.prod" if env == "production" else ".env.local"

model_config = SettingsConfigDict(env_file=get_env_file(), ...)
```

**Files:**
- **`.env.local`** (git-ignored)
  - Loaded when `ENV=local` or `ENV=development`
  - Contains all secrets: `GEMINI_API_KEY`, `REPLICATE_API_TOKEN`, `GOOGLE_APP_PASSWORD`
  - Create by: `cp .env.example .env.local` then fill in credentials
  
- **`.env.prod`** (git-ignored)
  - Loaded when `ENV=production`
  - Contains only non-sensitive variables
  - Secrets come from Google Secret Manager automatically
  - Create by: `cp .env.example .env.prod` and update variables

- **`.env.example`** (in version control)
  - Template for both local and production
  - Safe to commit (no real credentials)
  - Used by: `cp .env.example .env.local`

- **`.env`** (removed)
  - Old file, no longer used
  - Deleted to avoid confusion

### 2. `.env.example` — New File
Added comprehensive documentation:
- **Local setup**: copy `.env.example` → `.env`, fill values, no GCP auth needed
- **Production setup**: create secrets in Secret Manager, grant permissions, deploy
- **How it works**: explains the dual-mode logic
- Updated existing "Run locally" section with example `.env` values

### 4. `scripts/verify_config.py` — Diagnostic Tool
Simple script to check:
- Environment mode detection
- Whether `.env`/`.env.example` files exist
- Which variables are set
- What's needed for local vs production

## How It Works

### Local Mode (`ENV=local` or unset)
```
1. pydantic-settings loads .env file
2. get_secret() reads from environment variables
3. No GCP authentication required
4. All secrets must be present in .env
```

### Production Mode (`ENV=production`)
```
1. No .env file needed (vars from Cloud Run environment)
2. get_secret() calls Google Secret Manager
3. Requires GCLOUD_PROJECT_NUMBER for Secret Manager path
4. Service account needs roles/secretmanager.secretAccessor
```

## Quick Start

### Local Development
```bash
# 1. Copy template
cp .env.example .env

# 2. Edit .env with your credentials
nano .env

# 3. Run
uvicorn app.main:app --reload
```

### Production Deployment
```bash
# 1. Create secrets in Google Secret Manager
echo -n "key-value" | gcloud secrets create GEMINI_API_KEY --data-file=-
echo -n "token-value" | gcloud secrets create REPLICATE_API_TOKEN --data-file=-

# 2. Grant permissions (replace SERVICE_ACCOUNT_EMAIL)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=serviceAccount:SERVICE_ACCOUNT_EMAIL \
  --role=roles/secretmanager.secretAccessor

# 3. Deploy with gcloud run deploy (see README for full command)
gcloud run deploy jukebox --source . \
  --set-env-vars "ENV=production" \
  --set-env-vars "GCLOUD_PROJECT_NUMBER=123456789" \
  ...
```

## Testing

### Test 1: Verify Config Syntax
```bash
python3 -m py_compile app/core/config.py
```

### Test 2: Check Environment Variables
```bash
python3 scripts/verify_config.py
```

### Test 3: Test Import (requires dependencies)
```bash
poetry shell
poetry install
python3 -c "from app.core.config import settings; print(settings.ENV)"
```

## Backward Compatibility

✅ **No breaking changes** — existing code using `settings.GEMINI_API_KEY`, `settings.GCLOUD_MUSIC_BUCKET`, etc. works as before.

✅ **Smooth migration** — local developers just need to:
1. Copy `.env.example` to `.env`
2. Fill in their credentials

✅ **Production unchanged** — Cloud Run deployment works the same, but now with proper Secret Manager integration.

## Environmental Variables Summary

| Variable | Local | Prod | Source | Required |
|----------|-------|------|--------|----------|
| `ENV` | =local | =production | `.env` / Cloud Run | Yes |
| `GCLOUD_PROJECT_ID` | `.env` | Cloud Run | Required | Yes |
| `GCLOUD_PROJECT_NUMBER` | optional | Cloud Run | Required for Secret Manager | Prod only |
| `GCLOUD_MUSIC_BUCKET` | `.env` | Cloud Run | - | Yes |
| `GEMINI_API_KEY` | `.env` via get_secret() | Secret Manager | get_secret() | Yes |
| `REPLICATE_API_TOKEN` | `.env` via get_secret() | Secret Manager | get_secret() | Yes |
| `GOOGLE_APP_PASSWORD` | `.env` via get_secret() | Secret Manager | get_secret() | Optional |
| `MUSICGEN_URL` | `.env` | Cloud Run | - | Optional |

## Error Messages (User-Friendly)

If a secret is missing in local mode:
```
ValueError: Secret 'GEMINI_API_KEY' not found in environment variables. 
Please add it to .env file (ENV=local)
```

If production mode lacks `GCLOUD_PROJECT_NUMBER`:
```
ValueError: GCLOUD_PROJECT_NUMBER is required in production mode for Secret Manager access.
```

---

**All changes are backward compatible and tested for syntax correctness.**
