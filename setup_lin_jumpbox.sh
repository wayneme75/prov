#!/bin/bash
# Prep Ubuntu box with AzCli, Kubectl, Kubelogin, Go, Make, GH Cli and NetTools
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

# Use secure temporary file instead of predictable path
TEMP_MS_KEY=$(mktemp /tmp/microsoft.asc.XXXXXX)
curl -sSL https://packages.microsoft.com/keys/microsoft.asc -o "$TEMP_MS_KEY"

# Verify Microsoft GPG key fingerprint
# Expected fingerprint: BC52 8686 B50D 79E3 39D3 721C EB3E 94AD BE12 29CF
ACTUAL_FINGERPRINT=$(gpg --with-colons --import-options show-only --import "$TEMP_MS_KEY" 2>/dev/null | awk -F: '/fpr:/ {print $10; exit}')
EXPECTED_FINGERPRINT="BC528686B50D79E339D3721CEB3E94ADBE1229CF"

if [ "$ACTUAL_FINGERPRINT" = "$EXPECTED_FINGERPRINT" ]; then
    echo "✅ Microsoft GPG key fingerprint verified"
    sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/microsoft.gpg "$TEMP_MS_KEY"
else
    echo "❌ ERROR: Microsoft GPG key fingerprint mismatch!"
    echo "Expected: $EXPECTED_FINGERPRINT"
    echo "Got: $ACTUAL_FINGERPRINT"
    rm "$TEMP_MS_KEY"
    exit 1
fi

rm "$TEMP_MS_KEY"

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

# Update system packages
sudo apt-get update

# Install dependencies for apt repo
sudo apt-get install -y apt-transport-https ca-certificates curl

# Download and install the GPG key with verification
sudo mkdir -p /etc/apt/keyrings
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Use secure temporary file for Kubernetes GPG key
TEMP_K8S_KEY=$(mktemp /tmp/kubernetes-key.XXXXXX)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key -o "$TEMP_K8S_KEY"

# Verify the key was downloaded successfully
if [ ! -s "$TEMP_K8S_KEY" ]; then
    echo "❌ ERROR: Failed to download Kubernetes GPG key"
    rm "$TEMP_K8S_KEY"
    exit 1
fi

sudo gpg --dearmor --yes --batch -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg "$TEMP_K8S_KEY"
rm "$TEMP_K8S_KEY"

# Add Kubernetes APT repo
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update again and install kubectl
sudo apt-get update
sudo apt-get install -y kubectl

# -----------------------------
# Install Kubelogin
# -----------------------------
echo "Installing kubelogin..."

# Pin to specific version for security and reproducibility
KUBELOGIN_VERSION="v0.1.3"
# IMPORTANT: Replace with actual SHA256 from https://github.com/Azure/kubelogin/releases/tag/v0.1.3
# To get the checksum, download the file and run: sha256sum kubelogin-linux-amd64.zip
KUBELOGIN_SHA256=""  # MUST be filled in before production use

# Create secure temporary directory
TEMP_DIR=$(mktemp -d /tmp/kubelogin.XXXXXX)

# Download kubelogin with specific version
curl -sL "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip" -o "${TEMP_DIR}/kubelogin.zip"

# Verify checksum if provided
if [ -n "$KUBELOGIN_SHA256" ]; then
    echo "Verifying kubelogin checksum..."
    echo "${KUBELOGIN_SHA256}  ${TEMP_DIR}/kubelogin.zip" | sha256sum --check --status || {
        echo "❌ ERROR: Kubelogin checksum verification failed"
        rm -rf "$TEMP_DIR"
        exit 1
    }
    echo "✅ Kubelogin checksum verified"
else
    echo "⚠️  WARNING: Kubelogin checksum verification is DISABLED"
    echo "    For production use, obtain the SHA256 hash from:"
    echo "    https://github.com/Azure/kubelogin/releases/tag/${KUBELOGIN_VERSION}"
    echo "    and set KUBELOGIN_SHA256 variable"
fi

sudo apt install -y unzip
unzip -o "${TEMP_DIR}/kubelogin.zip" -d "${TEMP_DIR}"
sudo mv "${TEMP_DIR}/bin/linux_amd64/kubelogin" /usr/local/bin/
sudo chmod +x /usr/local/bin/kubelogin
rm -rf "$TEMP_DIR"

kubelogin --version

# -----------------------------
# Install Helm
# -----------------------------
echo "Installing Helm..."

# Use official Helm installation method with verification
# Pin to specific version for security
HELM_VERSION="v3.14.0"

# Create secure temporary directory
TEMP_HELM_DIR=$(mktemp -d /tmp/helm.XXXXXX)

# Download Helm binary directly instead of piping script to bash
curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o "${TEMP_HELM_DIR}/helm.tar.gz"

# Download checksum file for verification
curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz.sha256sum" -o "${TEMP_HELM_DIR}/helm.tar.gz.sha256sum"

# Verify checksum
cd "${TEMP_HELM_DIR}" && sha256sum --check helm.tar.gz.sha256sum || {
    echo "❌ ERROR: Helm checksum verification failed"
    rm -rf "$TEMP_HELM_DIR"
    exit 1
}

echo "✅ Helm checksum verified"

# Extract and install
tar -xzf "${TEMP_HELM_DIR}/helm.tar.gz" -C "${TEMP_HELM_DIR}"
sudo mv "${TEMP_HELM_DIR}/linux-amd64/helm" /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm

# Cleanup
rm -rf "$TEMP_HELM_DIR"

# Verify
helm version

# Update again and install GH CLI
echo "Installing GitHub CLI..."
sudo apt-get update
sudo apt-get install -y gh

gh --version

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

# kubelogin
if command -v kubelogin &>/dev/null; then
    echo "✅ kubelogin installed (git hash): $(kubelogin --version | grep "git hash" | awk '{print $3}')"
else
    echo "❌ kubelogin NOT installed"
fi

# helm
if command -v helm &>/dev/null; then
    echo "✅ helm installed: $(helm version --short)"
else
    echo "❌ helm NOT installed"
fi

# GH CLI 
if command -v gh &>/dev/null; then
    echo "✅ GH CLI installed: $(gh --version | head -n1)"
else
    echo "❌ GH CLI NOT installed"
fi

# Net-tools
if command -v ifconfig &>/dev/null; then
    echo "✅ net-tools installed"
else
    echo "❌ net-tools NOT installed"
fi

# --- REBOOT ---
while true; do
  read -rp "Do you want to reboot now? (y/n): " REBOOT
  # Convert to lowercase for comparison
  REBOOT=${REBOOT,,}

  if [[ "$REBOOT" == "y" ]]; then
    echo "Rebooting..."
    sudo reboot
    break
  elif [[ "$REBOOT" == "n" ]]; then
    echo "Reboot canceled."
    break
  else
    echo "Invalid input. Please enter 'y' or 'n'."
  fi
done


echo "==== Provisioning SUCCESSFUL on $(date) ===="
