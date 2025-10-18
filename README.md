# 🚀 Inventory Management Portal — CI/CD Pipeline with Deployment & Rollback

## 📘 Project Overview

This project implements a **reliable CI/CD pipeline** for the Inventory Management Portal.  
- Builds the Flask app in a **Docker container**  
- Runs **automated tests** before deployment  
- Deploys automatically to **remote EC2**  
- Provides **manual and automatic rollback**  

---
##Points to note while running and testing locally

- While running on remote machine pass values to secrets
- ## 🔐 GitHub Secrets Required

- **EC2_HOST** — IP or DNS of EC2 server  
- **EC2_USERNAME** — SSH user for EC2 (e.g., `ubuntu`)  
- **EC2_SSH_KEY** — Private key for SSH access  
- **GHCR_PAT** — GitHub Personal Access Token for Container Registry  (Pass this value if you're trying to pull the image from a private repository) The pipeline will fetch the secret value from this.

**These secrets are used in the deployment step to:**
- SSH into EC2  
- Pull Docker image from GHCR  
- Run the container securely  


## 📂 Repository Structure

```
├── main.py
├── requirements.txt
├── Dockerfile
├── .github/
│   └── workflows/
│       └── ci-cd.yml # GitHub Actions pipeline
├── scripts/
│   └── rollback.sh   # Manual rollback mechanism
└── README.md
```

## 📂 Local Testing 

Using the Dockerfile, run the container on your local machine:

```bash
git clone <repo-url>
cd inventory-app
docker build -t inventory-app:latest .
docker run -d -p 5000:5000 --name inventory-app-container inventory-app:latest
```

Access: http://localhost:5000

## 🖥️ Remote EC2 Setup

### 🧩 Step 1: Connect to EC2
```bash
ssh ubuntu@<EC2_HOST>
```

Always start by updating the package list and installing prerequisites:
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
```

### 🧩 Step 2: Add Docker’s official GPG key
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

### 🧩 Step 3: Set up the Docker repository
Now add the Docker repository to your sources list:
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 🧩 Step 4: Install Docker Engine
```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 🧩 Step 5: Verify Docker installation
Check if Docker service is active:
```bash
sudo systemctl status docker
```

Then check the Docker version:
```bash
docker --version
```

And run a test container:
```bash
sudo docker run hello-world
```

### 🧩 Step 6: Run Docker without sudo
By default, you need sudo to run Docker commands. To allow your user to run Docker directly:
```bash
sudo usermod -aG docker $USER
```


## ⚡ GitHub Actions Pipeline Steps

`ci-cd.yml` workflow:
- Checkout repository  
- Setup Python **3.11**  
- Install dependencies (`pip install -r requirements.txt`)  
- Run tests (`pytest`)  
- Build & push Docker image to **GHCR** (latest and SHA tags)  
- Deploy to EC2:  
  - SSH using `EC2_SSH_KEY`  
  - Pull image from GHCR  
  - Stop existing container  
  - Run new container  
  - Health check (HTTP 200)  
  - **Updates `.last_good_tag` and `.prev_good_tag`**  
  - **Auto rollback if deployment fails**  

## 🔁 Manual Rollback

To rollback to last stable deployment:
```bash
bash rollback.sh
```

**The script:**
- Stops the current container  
- Pulls the rollback image  
- Starts container  
- Runs health check  
- Updates `.last_good_tag` and `.prev_good_tag`  
