#!/bin/sh

# Install kpt package
sudo apt-get update && sudo apt-get install -y google-cloud-sdk-kpt

# Download the Anthos Service Mesh installation script to your home directory
cd ~
curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9.1-asm.1-config1 > install_asm

# Download the signature file and verify the signature
curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9.1-asm.1-config1.sha256 > install_asm.sha256
sha256sum -c install_asm.sha256

# Make the installation script executable
chmod +x install_asm

# Spring Media Production Cluster
# -------------------------------
# Configure kubectl command line access
gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --zone=${CLUSTER_LOCATION}

./install_asm --mode install --managed -p ${PROJECT_ID} \
    -l ${CLUSTER_LOCATION} -n ${PROD_CLUSTER_NAME} -v \
    --output_dir ${PROD_CLUSTER_NAME} --enable-all