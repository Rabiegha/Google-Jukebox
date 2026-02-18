# jukebox

## Description

Animations Ai @ Salon BigData

[GCP Project](https://console.cloud.google.com/home/dashboard?authuser=0&project=dgc-ai-jukebox&supportedpurview=project)

## Template Stack

- [FastApi](https://fastapi.tiangolo.com/)
- [Firestore client](https://firebase.google.com/docs/firestore)

## Project Setup

- Install [Poetry](https://python-poetry.org/docs/)

- Set config for venv in local

  ```sh
  poetry config virtualenvs.in-project true
  poetry env use 3.11
  poetry shell
  poetry install
  ```

### Environment Configuration

The application supports both **local development** and **production** environments using environment variables and Google Secret Manager.

#### Local Development Setup

1. Copy the example environment file:
   ```sh
   cp .env.example .env
   ```

2. Edit `.env` and fill in the required values:
   - `ENV=local` (or `development`)
   - `GCLOUD_PROJECT_ID` and `GCLOUD_PROJECT_NUMBER` (for GCS bucket access)
   - `GCLOUD_MUSIC_BUCKET` (e.g., `prompts_results`)
   - `GEMINI_API_KEY` (from GCP Console or Gemini API)
   - `REPLICATE_API_TOKEN` (if using Replicate API)
   - Other variables as needed

3. The `.env` file is loaded automatically at startup. All secrets are read from environment variables in local mode, so no Google Cloud authentication is required.

**Important**: Never commit `.env` to version control. The file is ignored by default.

#### Production Deployment (Cloud Run)

In production (`ENV=production`), secrets are retrieved from **Google Secret Manager**:

1. Create secrets in Google Secret Manager:
   ```bash
   echo -n "your-gemini-key" | gcloud secrets create GEMINI_API_KEY --data-file=-
   echo -n "your-replicate-token" | gcloud secrets create REPLICATE_API_TOKEN --data-file=-
   echo -n "your-email-password" | gcloud secrets create GOOGLE_APP_PASSWORD --data-file=-
   ```

2. Grant the Cloud Run service account the `Secret Accessor` role:
   ```bash
   gcloud projects add-iam-policy-binding PROJECT_ID \
     --member=serviceAccount:SERVICE_ACCOUNT_EMAIL \
     --role=roles/secretmanager.secretAccessor
   ```

3. Deploy with non-sensitive environment variables:
   ```bash
   gcloud run deploy jukebox --source . \
     --set-env-vars "ENV=production" \
     --set-env-vars "GCLOUD_PROJECT_ID=your-project-id" \
     --set-env-vars "GCLOUD_PROJECT_NUMBER=your-project-number" \
     --set-env-vars "GCLOUD_MUSIC_BUCKET=prompts_results" \
     --set-env-vars "MUSICGEN_URL=http://your-musicgen-vm:8000" \
     --set-env-vars "GOOGLE_APP_EMAIL=devoteam.jukebox@gmail.com" \
     --service-account=juke-box-service-account@dgc-ai-jukebox.iam.gserviceaccount.com \
     --min-instances=1 \
     --network=default \
     --subnet=default \
     --vpc-egress=private-ranges-only \
     --region=europe-west1
   ```

**How it works**:
- In local mode (`ENV=local`): Secrets are read from the `.env` file via pydantic-settings.
- In production mode (`ENV=production`): Secrets are fetched from Google Secret Manager using `GCLOUD_PROJECT_NUMBER`.

### Run locally

**The service DOES NOT ACCEPT a connection by default**
Make sure that the service at `MUSICGEN_URL` has the right firewall tags to accept traffic on port 8000 from the internet.

Otherwise set the following in `.env`:

```
ENV=local
MUSICGEN_URL=<url for vm that hosts musicgen_backend>
GOOGLE_APP_EMAIL=<gmail address>
GEMINI_API_KEY=<your-gemini-key>
REPLICATE_API_TOKEN=<your-replicate-token>
GCLOUD_PROJECT_ID=<your-gcp-project>
GCLOUD_PROJECT_NUMBER=<your-project-number>
GCLOUD_MUSIC_BUCKET=prompts_results
```

Run the service:

```sh
uvicorn app.main:app --reload
```

## Deployment

Use the following code to deploy the project as `jukebox` cloud run service.

Make sure you add the right external URL for the VM in the command below or in the configuration in the Google console!

## Api docs

- [Swagger](http://localhost:8000/api/docs)

## Maintainers

Digital Lab <fr.dgc.ops.dgtl@devoteamgcloud.com>
