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

### Run locally

**The service DOES NOT ACCEPT a connection by default**
Make sure that the service at `MUSICGEN_URL` has the right firewall tags to accept traffic on port 8000 from the internet.

Otherwise set the following:

```
MUSICGEN_URL=<url for vm that hosts musicgen_backend>
GOOGLE_APP_EMAIL=<gmail address>
```

**NOTE:** The `GOOGLE_APP_PASSWORD` and `GEMINI_API_KEY` are directly injected via secret manager, since they do normaly not need to change.

Run the service:

```sh
uvicorn app.main:app --reload
```

## Deployment

Use the following code to deploy the project as `jukebox` cloud run service.

Make sure you add the right external URL for the VM in the command below or in the configuration in the Google console!

**Note**: You have to adjust the VM name and zone depending on your Google Cloud configuration.

```bash
gcloud run deploy jukebox --source . --set-env-vars "MUSICGEN_URL=http://<vm-name>.<zone>.c.dgc-ai-jukebox.internal:8000" --set-env-vars "GOOGLE_APP_EMAIL=devoteam.jukebox@gmail.com" --service-account=juke-box-service-account@dgc-ai-jukebox.iam.gserviceaccount.com --min-instances=1  --network=default  --subnet=default  --vpc-egress=private-ranges-only --region=europe-west1
```

## Api docs

- [Swagger](http://localhost:8000/api/docs)

## Maintainers

Digital Lab <fr.dgc.ops.dgtl@devoteamgcloud.com>
