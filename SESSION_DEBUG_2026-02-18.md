# Session de Débogage - 18 Février 2026

## 🎯 Objectif Initial
Relancer l'environnement de développement et tester le workflow complet de création de musique sur tablette physique (Pixel Tablet).

## 🔧 Problèmes Rencontrés et Solutions

### 1. Docker Desktop Complètement Figé
**Problème:** Docker ne répondait plus à aucune commande (`docker ps`, `docker-compose`, etc.)

**Solution:**
```bash
killall -9 Docker
killall -9 com.docker.backend
open -a Docker.app
```

### 2. Configuration Firestore Incorrecte
**Problèmes multiples:**
- Mauvais ID de projet Google Cloud (`my-jukebox-app` au lieu de `jukebox-dev-b5e8e`)
- Service account credentials non montés dans Docker
- Endpoints backend crashaient sans gestion d'erreur

**Solutions appliquées:**

#### A. Modification `.env.local` (fr-google-jukebox)
```bash
GCLOUD_PROJECT_ID=jukebox-dev-b5e8e  # Corrigé de my-jukebox-app
```

#### B. Modification `docker-compose.local.yml`
Ajout du volume et variable d'environnement:
```yaml
volumes:
  - /Users/apple/Desktop/jukebox_local/jukebox-dev-b5e8e-firebase-adminsdk-fbsvc-7695cd6b82.json:/secrets/gcloud.json:ro
environment:
  - GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcloud.json
```

#### C. Ajout de gestion d'erreur dans `app/music/endpoints/music.py`
Modification des 3 endpoints principaux:
- `get_all_genres()`
- `get_all_instruments()`
- `get_musics_by_genre()`

Tous retournent maintenant des listes vides avec des logs en cas d'erreur Firestore au lieu de crasher.

### 3. Widget Flutter Ne Chargeait Pas les Genres
**Problème:** Le widget `music_style_widget.dart` n'appelait jamais l'API `getCategories()`

**Solution:** Réécriture complète du widget
- Ajout de `getCategories()` dans `initState()`
- Utilisation de `BlocBuilder<CategoryCubit, CategoryState>` pour réagir aux changements
- Affichage de "Loading..." pendant le chargement
- Affichage de "No genres available" si liste vide

**Fichier modifié:** `jukebox/lib/views/create_son/widgets/music_style_widget.dart`

### 4. Problème Réseau - Tablette Cannot Access Mac API
**Problème:** La tablette (ID: `3519105H807KAV`) ne peut pas accéder à l'API locale sur `http://192.168.1.106:8000`

**Tests effectués:**
```bash
# ✅ Sur Mac - fonctionne
curl http://localhost:8000/api/music/genre/all
curl http://192.168.1.106:8000/api/music/genre/all

# ✅ Ping depuis tablette - fonctionne
adb -s 3519105H807KAV shell "ping -c 1 192.168.1.106"

# ❌ HTTP depuis tablette - échoue
# Browser sur tablette: "site n'est pas accessible"
```

**Cause probable:** Pare-feu macOS, VPN, ou isolation WiFi AP bloquant le trafic HTTP

**Solution tentée:** Déploiement sur Cloud Run pour avoir une URL publique HTTPS

## 🚀 Tentative de Déploiement Cloud Run

### Installation Google Cloud SDK
```bash
# Échec via Homebrew (problème Python 3.13)
brew install google-cloud-sdk  # ❌

# Réussi via installation manuelle
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz
tar -xzf google-cloud-cli-darwin-arm.tar.gz
cd google-cloud-sdk
./install.sh --quiet --path-update true --command-completion true --usage-reporting false
```

**Version installée:** Google Cloud SDK 557.0.0

### Authentification et Configuration
```bash
gcloud auth login  # ✅ Réussi
gcloud config set project jukebox-dev-b5e8e  # ⚠️ Warning: pas de permissions
```

### Blocage Actuel
```bash
gcloud run deploy jukebox-api \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars ENV=production,GCLOUD_PROJECT_ID=jukebox-dev-b5e8e
```

**Erreur:** 
```
PERMISSION_DENIED: Permission denied to enable service [run.googleapis.com]
This command is authenticated as rgharghar@choyou.fr
```

**Compte actuel:** `rgharghar@choyou.fr` n'a pas les droits pour activer l'API Cloud Run

## 📊 Situation Actuelle

### ✅ Ce Qui Fonctionne
1. **Backend Docker local:** 3 conteneurs running
   - `jukebox_backend_local` (port 8000)
   - `jukebox_db_local` (PostgreSQL 5434)
   - `pgadmin_local` (port 5050)

2. **API Backend:** Répond correctement sur Mac
   ```bash
   curl http://localhost:8000/api/music/genre/all
   # Returns: 3 genres (Ambiente, Chill Out, Rock)
   ```

3. **Firestore:** Connexion établie, données récupérées
   - Collection: `jukebox` (3 genres)
   - Collection: `instrument` (instruments)
   - Sous-collection: `musics` (musiques par genre)

4. **Application Flutter:** Lancée sur tablette physique (device: `3519105H807KAV`)
   - Compilation OK
   - Installation OK
   - App s'ouvre sans crash

### ❌ Ce Qui Ne Fonctionne Pas
1. **Connectivité réseau:** Tablette → Mac API (port 8000)
   - Ping fonctionne
   - HTTP échoue (firewall/VPN/isolation)

2. **Affichage des genres dans l'app:** Widget ne reçoit pas les données de l'API
   - Cause: Pas d'accès réseau à l'API

3. **Déploiement Cloud Run:** Bloqué par permissions insuffisantes
   - Besoin: Activer l'API Cloud Run manuellement
   - OU: Se connecter avec un compte Owner/Editor

### 🔄 Discrepance Données
- **Instruments:** Hardcodés dans `instruments_widget.dart` (~10 instruments)
- **Genres:** Proviennent de l'API Firestore (3 genres actuellement)

## 📝 Commits Effectués

### Dépôt: fr-google-jukebox
```
a68cc73 - chore: Configure Docker compose with service account credentials for Firestore access
3726c7a - Fix Firestore error handling in music endpoints (genre, instruments, musics by genre)
```

### Dépôt: jukebox (Flutter)
```
22d1666 - Fix music genre display - add BlocBuilder and getCategories() call
```

## 🎯 Prochaines Étapes

### Option 1: Résoudre le Problème Réseau Local
1. Désactiver temporairement le pare-feu macOS
2. Vérifier les paramètres VPN
3. Tester avec un autre port (8080, 3000)
4. Utiliser `ngrok` pour tunneling HTTP

### Option 2: Déployer sur Cloud Run (Recommandé)
1. **Activer l'API Cloud Run manuellement:**
   - Aller sur: https://console.cloud.google.com/apis/library/run.googleapis.com?project=jukebox-dev-b5e8e
   - Cliquer sur "Activer"

2. **OU Se connecter avec un compte privilégié:**
   ```bash
   gcloud auth login
   # Se connecter avec un compte Owner/Editor
   ```

3. **Relancer le déploiement:**
   ```bash
   cd /Users/apple/Desktop/juke-box/fr-google-jukebox
   gcloud run deploy jukebox-api \
     --source . \
     --region europe-west1 \
     --allow-unauthenticated \
     --set-env-vars ENV=production,GCLOUD_PROJECT_ID=jukebox-dev-b5e8e
   ```

4. **Mettre à jour l'app Flutter:**
   - Créer/modifier `.env.prod` avec l'URL Cloud Run
   - Rebuild l'app: `flutter run -d 3519105H807KAV --dart-define=ENV=prod`

### Option 3: Utiliser l'Émulateur
1. Lancer l'émulateur sur Mac (où l'API est accessible):
   ```bash
   flutter emulators --launch Pixel_Tablet_API_36
   flutter run -d emulator-5554
   ```
2. API accessible via `http://10.0.2.2:8000` (bridge Android)

## 🗂️ Fichiers Importants

### Configuration
- `/Users/apple/Desktop/juke-box/fr-google-jukebox/.env.local`
- `/Users/apple/Desktop/juke-box/fr-google-jukebox/docker-compose.local.yml`
- `/Users/apple/Desktop/juke-box/jukebox/.env.local`

### Service Account
- `/Users/apple/Desktop/jukebox_local/jukebox-dev-b5e8e-firebase-adminsdk-fbsvc-7695cd6b82.json`

### Code Modifié
- `fr-google-jukebox/app/music/endpoints/music.py`
- `jukebox/lib/views/create_son/widgets/music_style_widget.dart`

## 🔍 Informations Système

- **OS:** macOS
- **Docker:** Desktop latest
- **Flutter:** 3.6.0-dev
- **Python:** 3.10.2 (backend), 3.13.4 (gcloud)
- **Google Cloud SDK:** 557.0.0
- **Device ID:** 3519105H807KAV (Pixel Tablet)
- **Mac IP:** 192.168.1.106
- **Backend Port:** 8000
- **GCP Project:** jukebox-dev-b5e8e
- **GCP Region:** europe-west1

## 💡 Notes
- `.env.local` est dans `.gitignore` (normal, ne pas commiter)
- `pgdata_local/` contient des stats PostgreSQL temporaires (ignorer dans git)
- Le compte `rgharghar@choyou.fr` a des permissions limitées sur le projet GCP
