#!/bin/bash

# Connect to the Spring Media Development Cluster
gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} --project=${PROJECT_ID} --zone=${CLUSTER_LOCATION}

# Install Tekton
kubectl apply -f https://github.com/tektoncd/pipeline/releases/download/v0.14.3/release.yaml

# Copy service-catalog.tgz from the release bucket folder and untar the archive
gsutil cp gs://kf-releases/${KF_VERSION}/service-catalog.tgz /tmp/service-catalog.tgz
tar xf /tmp/service-catalog.tgz -C /tmp

# Create service-catalog namespace
kubectl create namespace service-catalog

# Use Helm to upgrade Service Catalog.
helm upgrade service-catalog \
/tmp/service-catalog/charts/catalog/ \
--install \
--namespace service-catalog \
--values /tmp/service-catalog/values/catalog.yaml \
--set image=gcr.io/kf-releases/service-catalog:${KF_VERSION}

# The Kf CLI is already installed on our local machine so we just need to 
# deploy the server-side components on the Prod cluster
gsutil cp gs://kf-releases/${KF_VERSION}/kf.yaml /tmp/kf.yaml
kubectl apply -f /tmp/kf.yaml

# Setup Workload Identity for Kf and configuration
WI_ANNOTATION=iam.gke.io/gcp-service-account=${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com
kubectl annotate serviceaccount controller ${WI_ANNOTATION} \
--namespace kf \
--overwrite

echo "{\"apiVersion\":\"v1\",\"kind\":\"ConfigMap\",\"metadata\":{\"name\":\"config-secrets\", \"namespace\":\"kf\"},\"data\":{\"wi.googleServiceAccount\":\"${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com\"}}" | kubectl apply -f -

# Setup ‘Kf’ defaults. The defaults below use domain templates with a wildcard DNS provider to provide each Space its own domain name:
export PROD_ARTIFACT_REGISTRY=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${PROD_CLUSTER_NAME}
export DOMAIN='$(SPACE_NAME).$(CLUSTER_INGRESS_IP).nip.io'
kubectl patch configmaps config-defaults \
-n=kf \
-p="{\"data\":{\"spaceContainerRegistry\":\"${PROD_ARTIFACT_REGISTRY}\",\"spaceClusterDomains\":\"- domain: ${DOMAIN}\"}}"

# Test the Kf installation
kf doctor

# Install a Basic Service Broker, MiniBroker
helm repo add minibroker https://minibroker.blob.core.windows.net/charts
kubectl create namespace minibroker
helm install minibroker --namespace minibroker minibroker/minibroker

# Install the Spring Books application on Production cluster
cd ~/migrate-kf-anthos-demo/spring-books

kubectl create ns spring-books
kubectl label namespace spring-books istio-injection=enabled
kubectl apply -f spring-books.yaml -n spring-books
# TODO: Validate services/pods were deployed successfully
# kubectl get services -n spring-books
# kubectl get pod -n spring-books
kubectl apply -f spring-books-gateway.yaml -n spring-books
# TODO: Validate istio-ingressgateway has an external IP address
# kubectl get svc istio-ingressgateway -n istio-system

# Install Spring Music application on Production cluster
cd ~/migrate-kf-anthos-demo/spring-music

kf create-space spring-music
kf target -s spring-music
kf create-service postgresql 11-7-0 spring-music-db -c '{"postgresqlDatabase":"smdb", "postgresDatabase":"smdb"}'
kf push spring-music --no-start
kf start spring-music

# TODO: Validate the response from calling the auto-generated URL
# kf apps



