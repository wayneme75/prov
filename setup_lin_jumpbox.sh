#!/bin/bash
# Prep Ubuntu box with AzCli, Kubectl, Go, Make, and NetTools
# Works when downloaded from GitHub and run as: curl -sLO <url> && bash <script>

set -euo pipefail

LOGFILE="$HOME/provision.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "==== Starting Provisioning on $(date) ===="

# -----------------------------
# Update package index
# -----------------------------
echo "Updating package index..."
sudo apt update -y

# -----------------------------
# Install prerequisites
# -----------------------------
echo "Installing prerequisites..."
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg build-essential gcc make net-tools

# -----------------------------
# Add Microsoft’s GPG Key and Azure CLI repo
# -----------------------------
echo "Adding Microsoft GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -sSL https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc
sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/microsoft.gpg /tmp/microsoft.asc
rm /tmp/microsoft.asc

echo "Adding Azure CLI repo..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/azure-cli.list

echo "Updating repositories..."
sudo apt-get update -y

# -----------------------------
# Install Azure CLI
# -----------------------------
echo "Installing Azure CLI..."
sudo apt-get install -y azure-cli
az version

# -----------------------------
# Install Go
# -----------------------------
echo "Installing Go..."
sudo apt install -y golang-go
go version

# -----------------------------
# Verify Make
# -----------------------------
echo "Verifying Make..."
make --version

# -----------------------------
# Install kubectl
# -----------------------------
echo "Installing kubectl..."

# Get stable version
sudo apt-get install -y kubectl
kubectl version --client


# -----------------------------
# Verify net-tools
# -----------------------------
echo "Verifying net-tools installation..."
ifconfig || echo "ifconfig not available."

# -----------------------------
# Final Success Summary
# -----------------------------
echo
echo "==== Verifying all installations ===="

# Azure CLI
if command -v az &>/dev/null; then
    echo "✅ Azure CLI installed: $(az version --query '["azure-cli"]' -o tsv)"
else
    echo "❌ Azure CLI NOT installed"
fi

# Go
if command -v go &>/dev/null; then
    echo "✅ Go installed: $(go version)"
else
    echo "❌ Go NOT installed"
fi

# Make
if command -v make &>/dev/null; then
    echo "✅ Make installed: $(make --version | head -n1)"
else
    echo "❌ Make NOT installed"
fi

# kubectl
if command -v kubectl &>/dev/null; then
    echo "✅ kubectl installed: $(kubectl version --client | grep "Client Version" | awk '{print $3}')"
else
    echo "❌ kubectl NOT installed"
fi

# Net-tools
if command -v ifconfig &>/dev/null; then
    echo "✅ net-tools installed"
else
    echo "❌ net-tools NOT installed"
fi

echo "==== Provisioning SUCCESSFUL on $(date) ===="
