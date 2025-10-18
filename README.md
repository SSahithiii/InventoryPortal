# 🚀 Inventory Management Portal — CI/CD Pipeline with Deployment & Rollback

## 📘 Project Overview

This project implements a **reliable CI/CD pipeline** for the Inventory Management Portal.  
- Builds the Flask app in a **Docker container**  
- Runs **automated tests** before deployment  
- Deploys automatically to **remote EC2**  
- Provides **manual and automatic rollback**  

---

## 📂 Repository Structure

├── main.py
├── requirements.txt
├── Dockerfile
├── .github/
│ └── workflows/
│ └── ci-cd.yml # GitHub Actions pipeline
├── scripts/
│ └── rollback.sh # Manual rollback mechanism
└── README.md

Using the dockerFile run the container in the local machine.
git clone <repo-url>
cd inventory-app
docker build -t inventory-app:latest .
docker run -d -p 5000:5000 --name inventory-app-container inventory-app:latest

Access: http://localhost:5000

🔐 GitHub Secrets Required

The pipeline requires these GitHub repository secrets:

Secret Name	Description
EC2_HOST	IP or DNS of EC2 server
EC2_USERNAME	SSH user for EC2 (e.g., ubuntu)
EC2_SSH_KEY	Private key for SSH access
GHCR_PAT	GitHub Personal Access Token for Container Registry

These secrets are used in the deployment step to:

SSH into EC2

Pull Docker image from GHCR

Run the container securely

⚡ GitHub Actions Pipeline Steps :
ci-cd.yml workflow:
 Checkout repository
 Setup Python 3.11
 Install dependencies (pip install -r requirements.txt)
 Run tests (pytest)
 Build & push Docker image to GHCR (latest and SHA tags)
 Deploy to EC2:
 SSH using EC2_SSH_KEY
 Pull image from GHCR
 Stop existing container
 Run new container
 Health check (HTTP 200)
 Auto rollback if deployment fails


 🖥️ Remote EC2 Setup
1️⃣ Connect to EC2
ssh ubuntu@<EC2_HOST>

2️⃣ Install Docker
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker

3️⃣ Create Rollback State Directory
mkdir -p ~/.inventory_state

Stores:
.last_good_tag → last successful image
.prev_good_tag → previous successful image
.deploy_history → deployment log

🔁 Manual Rollback

To rollback to last good deployment:
bash scripts/rollback.sh

To rollback to previous deployment:
ROLLBACK_PREV=1 bash scripts/rollback.sh


The script:
Stops the current container
Pulls the rollback image
Starts container
Runs health check
Updates .last_good_tag and .prev_good_tag
