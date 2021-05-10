#!/bin/sh

# Remove the .kube/config file and .kf file to ensure Production resources get deployed in the Production cluster
rm ~/.kube/config

# Connect to the Spring Media Production Cluster
gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} --project=${PROJECT_ID} --zone=${CLUSTER_LOCATION}
export CONTEXT=$(kubectl config current-context)

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