# 🎵 Jukebox - Configuration et Test Local

## Architecture

### Backend (FastAPI)
- **Framework**: FastAPI + SQLAlchemy + Pydantic
- **Databases**: PostgreSQL main + test
- **Services**: Google Cloud (Firestore, Storage, Vertex AI)
- **Port**: 8000

### Frontend (Flutter)
- **Framework**: Flutter with BLoC pattern
- **Configuration**: Environment-based (.env.local / .env.prod)
- **API Client**: Dio with dynamic base URL

## Configuration Locale vs Production

### Backend Configuration

```python
# app/core/config.py
- ENV variable determines mode
- LOCAL: reads from .env.local (env vars)
- PROD: reads from Google Secret Manager

# Lazy Loading Pattern
- Firestore client: Initialize only on first use
- CloudStorage client: Initialize only on first use
- Google models (Gemini, Imagen): Initialize on first call
- Allows app to start without credentials
```

### Frontend Configuration

```dart
// lib/config/app_config.dart
- AppConfig.init(env: 'local') loads .env.local
- AppConfig.init(env: 'prod') loads .env.prod

// .env.local
API_BASE_URL=http://10.0.2.2:8000/api/

// .env.prod
API_BASE_URL=https://jukebox-1048249386206.europe-west1.run.app/api/
```

## Key Features Implemented

### 1. ✅ Local Development Setup
- Docker Compose for all services
- Auto-reload for Python code changes
- Hot reload for Flutter
- Environment variable isolation

### 2. ✅ Dual-Mode Music Generation
- **Replicate API** for audio generation (works everywhere)
- **Test mode**: Returns mock audio when Firestore unavailable
- Seamless fallback for local testing

### 3. ✅ Optional Cloud Services
- Firestore optional (fallback on local testing)
- Cloud Storage optional
- Google Auth optional
- All services gracefully degrade without credentials

### 4. ✅ Environment Configuration
- Backend: .env.local / .env.prod
- Frontend: .env.local / .env.prod
- Easy switching without code changes

## Local Testing Workflow

### 1. Start Backend
```bash
cd fr-google-jukebox
docker-compose -f docker-compose.local.yml up -d
```

### 2. Start Android Emulator
```bash
flutter emulators --launch Pixel_Tablet_API_36
```

### 3. Run Flutter App
```bash
cd jukebox
flutter run -d emulator-5554
```

### 4. Test Features
- Load genres: `GET /api/music/genre/all`
- Create song: `POST /api/music/uuid` (returns UUID)
- Generate music: `GET /api/music/song/stream?uuid=...&genre=...`
- Generate cover: `POST /api/music/cover`

## Known Limitations (Local Mode)

### Without Google Cloud Credentials
- ❌ Firestore read/write → Graceful fallback
- ❌ Cloud Storage access → Graceful fallback
- ❌ Imagen image generation → Requires API key
- ✅ Gemini text generation → Requires API key
- ✅ Replicate music generation → Requires API key

### API Endpoints Requiring Credentials
- `/api/music/genre/all` - Reads from Firestore
- `/api/music/instrument/all` - Reads from Firestore
- `/api/music/cover` - Uses Imagen (requires API key)
- `/api/music/song/stream` - Update Firestore (graceful fallback)

## Troubleshooting

### App stuck on "Create New Song"
**Problem**: Firestore credentials missing
**Solution**: Already fixed - Firestore calls are now optional with fallback

### App can't reach API
**Problem**: Emulator can't resolve `10.0.2.2`
**Solution**: 
- For Android emulator: `10.0.2.2` → Host machine
- For iOS simulator: `localhost` or `127.0.0.1`

### API responds but app doesn't load data
**Problem**: Missing required fields in request
**Solution**: Check repository classes for required fields

## Next Steps for Production

1. Setup Google Cloud credentials
2. Enable Firestore with proper indexes
3. Setup Cloud Storage buckets
4. Deploy backend to Cloud Run
5. Update frontend .env.prod with production URL
6. Test E2E with actual Google Cloud services

## Environment Variables

### Backend
```bash
# .env.local
ENV=local
GEMINI_API_KEY=...
REPLICATE_API_TOKEN=...
GCLOUD_PROJECT_ID=...
MUSICGEN_URL=http://musicgen:8001  # If using local service

# .env.prod
ENV=prod
GCLOUD_PROJECT_ID=...
# Secrets fetched from Google Secret Manager
```

### Frontend
```bash
# .env.local
API_BASE_URL=http://10.0.2.2:8000/api/
ENVIRONMENT=local

# .env.prod
API_BASE_URL=https://jukebox-1048249386206.europe-west1.run.app/api/
ENVIRONMENT=prod
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│          (/jukebox - Android/iOS/Web)                  │
│                                                         │
│  [AppConfig] → loads .env.local/.env.prod             │
│       ↓                                                │
│  [Repositories] → uses AppConfig.apiBaseUrl           │
│       ↓                                                │
│  Dio HTTP Client → calls API                          │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓ (10.0.2.2:8000 from emulator)
┌─────────────────────────────────────────────────────────┐
│               FastAPI Backend                           │
│        (/fr-google-jukebox Docker)                     │
│                                                         │
│  [Router] → [Endpoints]                               │
│       ↓                                               │
│  [Services] (lazy-loaded)                            │
│  ├─ Firestore (optional)                            │
│  ├─ CloudStorage (optional)                         │
│  ├─ Gemini (lazy)                                  │
│  ├─ Imagen (lazy)                                  │
│  └─ Replicate (always available)                   │
│       ↓                                              │
│  [Database] PostgreSQL                              │
└─────────────────────────────────────────────────────────┘
```

## Testing Commands

```bash
# Test create song UUID
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "genre": "Rock",
    "title": "Test Song",
    "prompt": "test",
    "creator": "Artist",
    "duration": 20
  }' \
  http://localhost:8000/api/music/uuid

# Test music generation (streaming)
curl "http://localhost:8000/api/music/song/stream?uuid=123&genre=Rock&title=Test&prompt=test&duration=15" \
  -o music.wav

# Test API docs
open http://localhost:8000/api/docs
```
