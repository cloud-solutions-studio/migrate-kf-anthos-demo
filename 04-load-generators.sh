# Install dependencies for Load Generators
sudo apt-get -y install jq

# Connect to the Spring Media cluster
gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} --project=${PROJECT_ID} --zone=${CLUSTER_LOCATION}

# Spring Books Load Generator
# -------------------------------
cd ~/migrate-kf-anthos-demo/load-generators/spring-books
export SPRING_BOOKS_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o json | jq -r ".status.loadBalancer.ingress[0].ip")

# Insert the Istio Ingress Gateway IP into the Spring Books Load Generator yaml file
sed -i "s/SPRING_BOOKS_URL/${SPRING_BOOKS_URL}/g" spring-books-load-generator.yaml

# Deploy the Spring Books Load Generator to the cluster
kubectl apply -f spring-books-load-generator.yaml

# Spring Music Load Generator
# -------------------------------
# cd ~/migrate-kf-anthos-demo/load-generators/spring-music
# export SPRING_MUSIC_URL=$(kf apps -o json | jq -r ".items[0].status.urls[0]" | sed "s/.\{1\}$//")
# export PROD_ARTIFACT_REGISTRY=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${PROD_CLUSTER_NAME}-artifact-registry

# Build the Spring Music Load Generator container image and store in Artifact Registry
# gcloud builds submit --tag ${PROD_ARTIFACT_REGISTRY}/spring-music-load-generator

# Deploy the Spring Music Load Generator to the cluster
# envsubst < spring-music-load-generator.yaml | kubectl apply -f -