🚀 Inventory Management Portal — CI/CD Pipeline with Deployment & RollbackThis project establishes a reliable CI/CD pipeline for the Inventory Management Portal, incorporating best practices for automated testing, deployment, and resilient rollback mechanisms.📘 Project FeaturesBuilds the Flask application within a Docker container.Runs automated tests before deployment to ensure code quality.Deploys automatically to a remote EC2 instance.Provides both manual and automatic rollback functionality for quick recovery.📂 Repository Structure├── main.py              # Main Flask application file
├── requirements.txt     # Python dependencies
├── Dockerfile           # Defines the Docker image build
├── .github/
│ └── workflows/
│ └── ci-cd.yml      # GitHub Actions pipeline workflow
├── scripts/
│ └── rollback.sh    # Manual rollback mechanism script
└── README.md
🐳 Local ExecutionTo run the application locally using Docker:Clone the repository:Bashgit clone <repo-url>
cd inventory-app
Build the Docker image:Bashdocker build -t inventory-app:latest .
Run the container:Bashdocker run -d -p 5000:5000 --name inventory-app-container inventory-app:latest
Access the application at: http://localhost:5000🔐 GitHub Secrets RequiredThe CI/CD pipeline's deployment step relies on the following GitHub repository secrets:Secret NameDescriptionEC2_HOSTIP or DNS of the EC2 server.EC2_USERNAMESSH user for EC2 (e.g., ubuntu).EC2_SSH_KEYPrivate key for SSH access to the EC2 instance.GHCR_PATGitHub Personal Access Token for accessing the GitHub Container Registry (GHCR).These secrets are essential for securely:SSH-ing into the EC2 instance.Pulling the Docker image from GHCR.Running the container on the remote server.⚡ GitHub Actions Pipeline (ci-cd.yml)The workflow automates the following steps:Checkout repositorySetup Python 3.11Install dependencies (pip install -r requirements.txt)Run tests (pytest)Build & push Docker image to GHCR (tagged with both latest and a unique SHA).Deploy to EC2 via SSH:Authenticate using EC2_SSH_KEY.Pull the new image from GHCR.Stop the existing container.Run the new container.Health check (verifies HTTP 200 response).Auto rollback if the health check or deployment fails.🖥️ Remote EC2 Setup GuideEnsure your EC2 instance is prepared to host the Dockerized application.1. Connect to EC2Bashssh ubuntu@<EC2_HOST>
2. Install DockerExecute these commands on your EC2 instance to install and configure Docker:Bashsudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to the docker group for non-root execution
sudo usermod -aG docker $USER
newgrp docker # Apply group changes immediately
3. Create Rollback State DirectoryThis directory stores metadata essential for rollback operations:Bashmkdir -p ~/.inventory_state
The directory stores:.last_good_tag: The tag of the last successful image deployment..prev_good_tag: The tag of the image that was successful before the last one..deploy_history: A log of all deployments.🔁 Manual RollbackThe scripts/rollback.sh utility allows for manual recovery to a previously stable version.Rollback ActionCommandTarget ImageTo the Last Good Deploymentbash scripts/rollback.shImage tagged in .last_good_tagTo the Previous DeploymentROLLBACK_PREV=1 bash scripts/rollback.shImage tagged in .prev_good_tagRollback Script LogicThe script performs the following steps:Stops the current running container.Pulls the designated rollback image (based on the environment variable).Starts a new container with the rollback image.Runs a health check on the new container.If successful, it updates .last_good_tag and .prev_good_tag to reflect the new stable state.
