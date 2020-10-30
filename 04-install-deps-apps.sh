#!/bin/bash

# Remove the .kube/config file and .kf file to ensure Production resources get deployed in the Production cluster
rm ~/.kube/config

# Connect to the Spring Media Development Cluster
gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} --project=${PROJECT_ID} --zone=${CLUSTER_LOCATION}
export CONTEXT=$(kubectl config current-context)

# Install Tekton
kubectl apply -f https://github.com/tektoncd/pipeline/releases/download/v0.14.3/release.yaml --context ${CONTEXT}

# The Kf CLI is already installed on our local machine so we just need to 
# deploy the server-side components on the Prod cluster
kubectl apply -f /tmp/kf.yaml --context ${CONTEXT}

# Setup Workload Identity for Kf and configuration
WI_ANNOTATION=iam.gke.io/gcp-service-account=${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com
kubectl annotate serviceaccount controller ${WI_ANNOTATION} \
--namespace kf \
--context ${CONTEXT} \
--overwrite

echo "{\"apiVersion\":\"v1\",\"kind\":\"ConfigMap\",\"metadata\":{\"name\":\"config-secrets\", \"namespace\":\"kf\"},\"data\":{\"wi.googleServiceAccount\":\"${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com\"}}" | kubectl apply -f -

# Setup Kf defaults. The defaults below use domain templates with a wildcard DNS provider to provide each Space its own domain name:
export PROD_ARTIFACT_REGISTRY=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${PROD_CLUSTER_NAME}
export DOMAIN='$(SPACE_NAME).$(CLUSTER_INGRESS_IP).nip.io'
kubectl patch configmaps config-defaults \
-n=kf \
-p="{\"data\":{\"spaceContainerRegistry\":\"${PROD_ARTIFACT_REGISTRY}\",\"spaceClusterDomains\":\"- domain: ${DOMAIN}\"}}"

# Wait for Kf to finish deployment
echo "Finalizing Kf deployment on Production cluster (~1m)..."
sleep 1m

# Test the Kf installation
kf doctor

# Install a Basic Service Broker, MiniBroker
helm repo add minibroker "https://minibroker.blob.core.windows.net/charts" --kube-context ${CONTEXT}
kubectl create namespace minibroker --context ${CONTEXT}
helm install minibroker minibroker/minibroker \
  --namespace minibroker \
  --set "deployServiceCatalog=false" \
  --kube-context ${CONTEXT}
sleep 10s
kf create-service-broker minibroker \
  "user" \
  "pass" \
  "http://minibroker-minibroker.minibroker.svc.cluster.local"

# Wait for Minibroker to finish deployment
echo "Finalizing Minibroker deployment on Production cluster (~2m)..."
sleep 1m
echo "Finalizing Minibroker deployment on Production cluster (~1m)..."
sleep 1m

# Install the Spring Books application on Production cluster
cd ~/migrate-kf-anthos-demo/spring-books

kubectl create ns spring-books --context ${CONTEXT}
kubectl label namespace spring-books istio-injection=enabled
envsubst < spring-books.yaml | kubectl apply -f -
kubectl apply -f spring-books-gateway.yaml

# Wait for Spring Books to finish deployment
echo "Finalizing Spring Books deployment on Production cluster (~1m)..."
sleep 1m

# Install Spring Music application on Production cluster
cd ~/migrate-kf-anthos-demo/spring-music

kf create-space spring-music
kf target -s spring-music
kf create-service postgresql 11-7-0 spring-music-db -c '{"postgresqlDatabase":"smdb", "postgresDatabase":"smdb"}'
kf push spring-music --no-start
kf start spring-music

# Delete Tekton pipeline pod
export TEKTON_POD=$(kubectl get pods -n spring-music --field-selector="status.phase=Failed" -o json | jq -r ".items[0].metadata.name")
kubectl delete pod ${TEKTON_POD} -n spring-music