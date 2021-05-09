#!/bin/bash

# Install kpt package
sudo apt-get update && sudo apt-get install -y google-cloud-sdk-kpt

# Download the Anthos Service Mesh installation script to your home directory
cd ~
curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9 > install_asm

# Download the signature file and verify the signature
curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9.sha256 > install_asm.sha256
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


# Wait for Anthos Service Mesh deployment to finish on Production cluster
while [[ $(kubectl get pods -n asm-system -l control-plane=controller-manager -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "Finalizing Anthos Service Mesh deployment on Production cluster..." && sleep 1; done


# Spring Media Development Cluster
# -------------------------------
# Configure kubectl command line access
gcloud container clusters get-credentials ${DEV_CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --zone=${CLUSTER_LOCATION}

./install_asm --mode install --managed -p ${PROJECT_ID} \
    -l ${CLUSTER_LOCATION} -n ${DEV_CLUSTER_NAME} -v \
    --output_dir ${DEV_CLUSTER_NAME} --enable-all

# Wait for Anthos Service Mesh deployment to finish on Development cluster
while [[ $(kubectl get pods -n asm-system -l control-plane=controller-manager -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "Finalizing Anthos Service Mesh deployment on Development cluster..." && sleep 1; done
