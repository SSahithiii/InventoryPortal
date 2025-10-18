🚀 Inventory Management Portal — CI/CD Pipeline Solution
📘 Project Overview
This repository contains a complete solution for the TDK DevOps case study. It implements a reliable, production-grade CI/CD pipeline for the Inventory Management Portal.

The key features of this solution are:

The Flask application is containerized using Docker.

Automated tests are run with pytest on every push to ensure code quality.

The application is automatically deployed to a remote AWS EC2 instance.

The pipeline includes an automated rollback mechanism that reverts the deployment if a health check fails.

A manual rollback script is also provided for operator-triggered reverts.

🏗️ Architecture Diagram
The CI/CD process follows the flow illustrated below:

graph TD
    A[Developer Pushes Code] --> B{GitHub Actions Pipeline};
    B --> C[1. Run Tests];
    C -- Tests Pass --> D[2. Build & Push Docker Image to GHCR];
    D --> E{3. Trigger Deployment on EC2};
    subgraph "AWS EC2 Instance"
        E --> F[Pulls New Image];
        F --> G[Starts New Container];
        G --> H{4. Health Check};
        H -- ✅ Passes --> I[Deployment Successful];
        H -- ❌ Fails --> J[5. Auto-Rollback to Previous Version];
    end

💻 How to Run Locally
You can build and run the application on your local machine using Docker.

Clone the repository:

git clone <your-repo-url>
cd <your-repo-name>

Build the Docker image:

docker build -t inventory-app:local .

Run the container:

docker run -d -p 5000:5000 --name inventory-app-container inventory-app:local

Access the application:
The API is now available at http://localhost:5000.

☁️ Remote EC2 Server Setup
The pipeline is designed to deploy to a standard Ubuntu EC2 instance. The following steps outline the one-time setup required on the server.

Step 1: Connect to EC2
ssh ubuntu@<EC2_HOST>

Step 2: Install Docker
Run the following commands to install Docker Engine on the server:

# Update package list and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL [https://download.docker.com/linux/ubuntu/gpg](https://download.docker.com/linux/ubuntu/gpg) | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] [https://download.docker.com/linux/ubuntu](https://download.docker.com/linux/ubuntu) \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

Step 3: Run Docker without sudo (Recommended)
To allow your ubuntu user to run Docker commands without sudo:

sudo usermod -aG docker $USER
# You will need to log out and log back in for this change to take effect.

🔐 GitHub Secrets Required
For the pipeline to connect to your EC2 instance securely, the following secrets must be set in your GitHub repository under Settings > Secrets and variables > Actions:

Secret Name

Description

EC2_HOST

The public IP address or DNS of the EC2 server.

EC2_USERNAME

The SSH user for the EC2 instance (e.g., ubuntu).

EC2_SSH_KEY

The private SSH key used to access the EC2 instance.

GHCR_PAT

A GitHub Personal Access Token with read:packages scope.

⚡ CI/CD Pipeline Explained
The entire workflow is defined in the .github/workflows/ci-cd.yml file and consists of three jobs:

test Job:

Checks out the code.

Sets up a Python 3.11 environment.

Installs all dependencies from requirements.txt.

Runs the automated test suite using pytest.

build-and-push Job:

Runs only if the test job succeeds.

Logs into the GitHub Container Registry (GHCR).

Builds the Docker image from the Dockerfile.

Pushes the image to GHCR with two tags: latest and the unique Git commit SHA for versioning.

deploy-to-ec2 Job:

Runs only if the build-and-push job succeeds.

Connects to the EC2 server via SSH using the provided secrets.

Executes a remote script that:

Logs the EC2 Docker daemon into GHCR.

Pulls the new version of the image.

Starts the new container with a temporary name.

Performs a health check to ensure the application is running correctly.

If healthy, it finalizes the deployment and updates state files (.last_good_tag).

If unhealthy, it triggers an automated rollback to the last known good version.

🔁 Rollback Mechanism
This solution provides two methods for rollbacks:

Automated Rollback
The deployment script has a built-in health check. If a new deployment fails to respond with a HTTP 200 OK status within a set time, the script automatically stops the failed container and redeploys the last known good version. The pipeline will fail, notifying the team of the issue.

Manual Rollback
For situations where a bug is discovered after a successful deployment, a manual rollback can be triggered. An authorized user can SSH into the EC2 server and run the rollback.sh script.

This script will:

Read the state files (.last_good_tag and .prev_good_tag) to find the previous stable version.

Pull that specific version from GHCR.

Stop the current container and start the old, stable one.

Run a health check to confirm the rollback was successful.
