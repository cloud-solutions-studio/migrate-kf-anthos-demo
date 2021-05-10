#!/bin/sh

# Remove the .kube/config file and .kf file to ensure Production resources get deployed in the Production cluster
rm ~/.kube/config

# Connect to the Spring Media Production Cluster
gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} --project=${PROJECT_ID} --zone=${CLUSTER_LOCATION}
export CONTEXT=$(kubectl config current-context)

# Install the Spring Books application on Production cluster
cd ~/migrate-kf-anthos-demo/spring-books

kubectl create ns spring-books --context ${CONTEXT}
kubectl label namespace spring-books istio-injection- istio.io/rev=asm-managed --overwrite
envsubst < spring-books.yaml | kubectl apply -f -
kubectl apply -f spring-books-gateway.yaml