# Jukebox VM Setup Guide

This README provides the instructions on how to set up and run the Jukebox service on a Google Cloud VM. The service is responsible for generating music based on user-selected genres and rhythms.

## Normal useage

Start the available instance. The included start up script will launch the service automatically

## VM Instance - Quick setup

If you need to create a new instance follow the instructions for the first time setup below and make sure you select the **template** and change the **disk snapshot**.

**Important**:
Make sure you have the correct internal hostname (its the name of the instance) set as environemnt variable in the orchistration [backend service](https://console.cloud.google.com/run/detail/europe-west1/jukebox/metrics?orgonly=true&project=dgc-ai-jukebox&supportedpurview=project).

Change <your_instance_name> to your instances name:
`http://<your_instance_name>.c.dgc-ai-jukebox.internal:8000`

## VM Instance - First time setup

### 1. Create a VM Instance

If the VM instance doesn't already exist, create it using the instance template `jukebox-streaming` or manually with the follwing specs:

- n1-standard-4
- 2x Nvidia T4
- Boot Disk image: c0-deeplearning-common-gpu-v20240730-debian-11-py310

#### Internal Hostname:

- Name the instance to `jukebox-instance`. This is important for the Cloud Run to correctly identify the instance's private hostname.
- If you choose a different name, make sure to update the Cloud Run env variable with the selected hostname.

#### Select Snapshot as disk:

- Select `jukebox-streaming-snapshot` as disk if available. This snapshot already has all dependencies, packages and models downloaded and installed and is ready to go. (**If selecte, the next steps are not necessary**)

## Dependencies and Installation (Only when no disk snapshot selected)

Once your VM is up and running, you'll need to set up the necessary environment and dependencies.

#### 1. Install GPU Dependencies

When you first connect to the VM, you will be prompted to install the necessary GPU-related dependencies.
Type `yes` when prompted.

#### 2. Run the Setup Script

Run the following script in a terminal to set up the environment:

```bash
#!/bin/bash
set -e

sudo mkdir /home/jukebox
sudo chmod 777 -R /home/jukebox

export HOME=/home/jukebox
cd ~

wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b
rm Miniconda3-latest-Linux-x86_64.sh
source ~/miniconda3/etc/profile.d/conda.sh

conda create --name jukebox_env python=3.9 -y
conda activate jukebox_env

conda install pytorch==2.1.0 torchvision torchaudio cudatoolkit=11.8 "ffmpeg<5" -c conda-forge -c pytorch -c nvidia -y

```

This script will:

- Create a directory for the Jukebox service that can be accessed by other users.
- Install Miniconda for managing Python environments.
- Create and activate a Conda environment named `jukebox_env`.
- Install PyTorch with GPU support

#### 3. Getting Repository

After the initial setup, clone this repository into the VM. (setup of SSH key might be needed)

```bash
git clone git@github.com:devoteamgcloud/fr-google-jukebox-musicgen.git
```

Make sure the conda env is activated

```bash
export HOME=/home/jukebox
cd ~
conda activate miniconda3/envs/jukebox_env
```

Install dependencies

```bash
pip install -U google-cloud-storage fastapi pydantic transformers python-dotenv wave httpx
```

## (Optional) Changing .env

If you want your generated music in another bucket, or change the used model change the .env file

## Run the service

In normal conditions the service is already up and running on startup.

Kill the running process first before starting the service manually:

```bash
ps aux
kill <pid of service>
```

It will be the service that uses a lot of GPU and Memory.

Aferwards you can launch the service

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

**Note**: If there are problems finding a cache make sure the application has the necessary permissions to write to the current directory

```bash
sudo chmod 777 -R /home/jukebox
```

This will start the FastAPI service on port 8000, making the Jukebox service accessible.

### (Additional) Automatically starting the service on startup

The `jukebox-streaming` template already has a startup script that will start the service on VM startup. If you want to add it manually or correct it:

Add the following under `Automation` -> `Startup script` in the VM settings:

```bash
#!/bin/bash

# Export HOME environment variable
export HOME=/home/jukebox

# Change directory to home
   cd ~

# Change permissions of the /home/jukebox directory
sudo chmod 777 -R /home/jukebox

# Activate the Conda environment
source ~/miniconda3/bin/activate jukebox_env

# Go into the git repo
cd fr-google-jukebox-musicgen

# Start the uvicorn server and redirect stdout and stderr to a log file
uvicorn main:app --host 0.0.0.0 --port 8000 > jukebox_service.log 2>&1 &
```

This script will:

- Set the home Path
- Allow write access
- Activate conda env
- Start the fastapi service and write the logs into a seperate file `jukebox_service.log`

## Useful Commands

- **Check the VM's Private Hostname**:

  ```bash
  curl "http://metadata.google.internal/computeMetadata/v1/instance/hostname" -H "Metadata-Flavor: Google"
  ```

- **Verify GPU Availability**:
  ```bash
  python -c "import torch; print(torch.cuda.is_available())"
  ```

## Additional Notes

- **Hostname Configuration**: Ensure the Cloud Run service is configured with the correct private hostname of the VM. If you change the VM instance name, update the Cloud Run configuration accordingly.

- **Cost Management**: GPU instances can be expensive. To minimize costs, make sure to stop the VM when it's not in use.
