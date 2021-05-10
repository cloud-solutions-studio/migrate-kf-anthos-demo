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
# Install Anthos Service Mesh with a fully-managed Control Plane and register to the project's environ
spring_media_prod_asm () {
    ./install_asm --mode install --managed -p ${PROJECT_ID} \
        -l ${CLUSTER_LOCATION} -n ${PROD_CLUSTER_NAME} -v \
        --output_dir ${PROD_CLUSTER_NAME} --enable-all --enable-registration

    gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} --zone ${CLUSTER_LOCATION} --project ${PROJECT_ID}
    
    istioctl install -f ~/${PROD_CLUSTER_NAME}/managed_control_plane_gateway.yaml --set revision=asm-managed -d ~/${PROD_CLUSTER_NAME}/istio-1.9.1-asm.1/manifests/
}

# Kf Cluster
# -------------------------------
# Install Anthos Service Mesh with a fully-managed Control Plane and register to the project's environ
kf_cluster_asm () {
    ./install_asm --mode install --managed -p ${PROJECT_ID} \
        -l ${CLUSTER_LOCATION} -n ${KF_CLUSTER_NAME} -v \
        --output_dir ${KF_CLUSTER_NAME} --enable-all

    gcloud container clusters get-credentials ${KF_CLUSTER_NAME} --zone ${CLUSTER_LOCATION} --project ${PROJECT_ID}

    istioctl install -f ~/${KF_CLUSTER_NAME}/managed_control_plane_gateway.yaml --set revision=asm-managed -d ~/${PROD_CLUSTER_NAME}/istio-1.9.1-asm.1/manifests/
}

echo "Starting installation of ASM on Spring Media Prod and Kf clusters..."
spring_media_prod_asm >> "/tmp/spring_media_prod_asm.log" &
spring_media_prod_asm_pid=$!
kf_cluster_asm >> "/tmp/kf_cluster_asm.log" &
kf_cluster_asm_pid=$!

wait $spring_media_prod_asm_pid
wait $kf_cluster_asm_pid
echo "Installation of ASM on Spring Media Prod and Kf clusters is complete..."