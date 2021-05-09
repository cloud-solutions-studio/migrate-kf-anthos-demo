#!/bin/bash

# Install kpt package
sudo apt-get update && sudo apt-get install -y google-cloud-sdk-kpt

# Spring Media Production Cluster
# -------------------------------
# Configure kubectl command line access
gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --zone=${CLUSTER_LOCATION}

# Grant cluster admin permissions to the current user. You need these permissions to create the necessary
# role based access control (RBAC) rules for Anthos Service Mesh
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user="$(gcloud config get-value core/account)"

# Download the Anthos Service Mesh installation file to your home directory
cd ~
curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9 > install_asm

# Download the signature file and use openssl to verify the signature
curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9.sha256 > install_asm.sha256
sha256sum -c install_asm.sha256

chmod +x install_asm
./install_asm --mode install --managed -p ${PROJECT_ID} \
    -l ${CLUSTER_LOCATION} -n ${PROD_CLUSTER_NAME} -v \
    --output_dir ${PROD_CLUSTER_NAME} --enable-all


# Wait for Anthos Service Mesh deployment to finish on Production cluster
while [[ $(kubectl get pods -n istio-system -l app=istiod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "Verifying Istiod deployment on Production cluster..." && sleep 1; done
while [[ $(kubectl get pods -n istio-system -l app=istio-ingressgateway -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "Verifying Istio Ingress Gateway deployment on Production cluster..." && sleep 1; done
while [[ $(kubectl get pods -n asm-system -l control-plane=controller-manager -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "Finalizing Anthos Service Mesh deployment on Production cluster..." && sleep 1; done

# Run both the basic and the security tests
asmctl validate --with-testing-workloads

# Spring Media Development Cluster
# -------------------------------
# Configure kubectl command line access
gcloud container clusters get-credentials ${DEV_CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --zone=${CLUSTER_LOCATION}

# Grant cluster admin permissions to the current user. You need these permissions to create the necessary
# role based access control (RBAC) rules for Anthos Service Mesh
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user="$(gcloud config get-value core/account)"

# Ensure that you're in the Anthos Service Mesh installation's root directory
cd ~/istio-1.6.11-asm.1

# Create a new directory for the Anthos Service Mesh package resource configuration files
mkdir ~/${DEV_CLUSTER_NAME}
cd ~/${DEV_CLUSTER_NAME}

# Download the asm package, which enables Mesh CA
kpt pkg get \
https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm@release-1.6-asm asm

# Set the project ID for the project that the cluster was created in
kpt cfg set asm gcloud.core.project ${PROJECT_ID}

# Set the project number for the environ host project
kpt cfg set asm gcloud.project.environProjectNumber ${PROJECT_NUMBER}

# Set the cluster name
kpt cfg set asm gcloud.container.cluster ${DEV_CLUSTER_NAME}

# Set the default zone or region
kpt cfg set asm gcloud.compute.location ${CLUSTER_LOCATION}

# Set the Anthos Service Mesh configuration profile
kpt cfg set asm anthos.servicemesh.profile asm-gcp

# Run the following command to install Anthos Service Mesh using the configuration profile that you set in the istio-operator.yaml file
istioctl install \
  -f asm/cluster/istio-operator.yaml

# Run the following command to deploy the Canonical Service controller
kubectl apply -f asm/canonical-service/controller.yaml

# Wait for Anthos Service Mesh deployment to finish on Development cluster
while [[ $(kubectl get pods -n istio-system -l app=istiod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "Verifying Istiod deployment on Development cluster..." && sleep 1; done
while [[ $(kubectl get pods -n istio-system -l app=istio-ingressgateway -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "Verifying Istio Ingress Gateway deployment on Development cluster..." && sleep 1; done
while [[ $(kubectl get pods -n asm-system -l control-plane=controller-manager -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "Finalizing Anthos Service Mesh deployment on Development cluster..." && sleep 1; done


# Run both the basic and the security tests
asmctl validate --with-testing-workloads
