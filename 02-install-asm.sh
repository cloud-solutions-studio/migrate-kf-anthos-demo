#!/bin/bash

# Install kpt package
sudo apt-get update && sudo apt-get install -y google-cloud-sdk-kpt

# Initialize your project to ready it for installation. Among other things, this command creates a service account to let control plane components,
# such as the sidecar proxy, securely access your project's data and resources.
curl --request POST \
  --header "Authorization: Bearer $(gcloud auth print-access-token)" \
  --data '' \
  "https://meshconfig.googleapis.com/v1alpha1/projects/${PROJECT_ID}:initialize"

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
curl -LO https://storage.googleapis.com/gke-release/asm/istio-1.6.11-asm.1-linux-amd64.tar.gz

# Download the signature file and use openssl to verify the signature
curl -LO https://storage.googleapis.com/gke-release/asm/istio-1.6.11-asm.1-linux-amd64.tar.gz.1.sig
openssl dgst -verify /dev/stdin -signature istio-1.6.11-asm.1-linux-amd64.tar.gz.1.sig istio-1.6.11-asm.1-linux-amd64.tar.gz <<'EOF'
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEWZrGCUaJJr1H8a36sG4UUoXvlXvZ
wQfk16sxprI2gOJ2vFFggdq3ixF2h4qNBt0kI7ciDhgpwS8t+/960IsIgw==
-----END PUBLIC KEY-----
EOF

# Extract the contents of the file to any location to the current working directory
tar xzf istio-1.6.11-asm.1-linux-amd64.tar.gz

# Ensure that you're in the Anthos Service Mesh installation's root directory
cd ~/istio-1.6.11-asm.1

# Add the tools in the /bin directory to your PATH
export PATH=$PWD/bin:$PATH

# Create a new directory for the Anthos Service Mesh package resource configuration files
mkdir ~/${PROD_CLUSTER_NAME}
cd ~/${PROD_CLUSTER_NAME}

# Download the asm package, which enables Mesh CA
kpt pkg get \
https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm@release-1.6-asm asm

# Set the project ID for the project that the cluster was created in
kpt cfg set asm gcloud.core.project ${PROJECT_ID}

# Set the project number for the environ host project
kpt cfg set asm gcloud.project.environProjectNumber ${PROJECT_NUMBER}

# Set the cluster name
kpt cfg set asm gcloud.container.cluster ${PROD_CLUSTER_NAME}

# Set the default zone or region
kpt cfg set asm gcloud.compute.location ${CLUSTER_LOCATION}

# Set the Anthos Service Mesh configuration profile
kpt cfg set asm anthos.servicemesh.profile asm-gcp

# Run the following command to install Anthos Service Mesh using the configuration profile that you set in the istio-operator.yaml file
istioctl install \
  -f asm/cluster/istio-operator.yaml

# Run the following command to deploy the Canonical Service controller
kubectl apply -f asm/canonical-service/controller.yaml

# Sleep 1 minute
echo "Finalizing Anthos Service Mesh deployment on Production cluster..."
sleep 1m

# Check that the control plane pods in istio-system are up
# if [ (kubectl get pod -n istio-system | grep -e 'istio-ingressgateway.*1/1.*Running') -a (kubectl get pod -n istio-system | grep -e 'istiod.*1/1.*Running') ] then echo "Control Plane Pods Up!" else echo "ERROR: Control Plane Pods Not Up!" fi

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

# Sleep 1 minute
echo "Finalizing Anthos Service Mesh deployment on Development cluster (~1m)..."
sleep 1m

# Check that the control plane pods in istio-system are up
# if [ (kubectl get pod -n istio-system | grep -e 'istio-ingressgateway.*1/1.*Running') -a (kubectl get pod -n istio-system | grep -e 'istiod.*1/1.*Running') ] then echo "Control Plane Pods Up!" else echo "ERROR: Control Plane Pods Not Up!" fi

# Run both the basic and the security tests
asmctl validate --with-testing-workloads
