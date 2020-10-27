# Install dependencies for Load Generators
sudo apt-get -y install jq
sudo apt-get install -y siege

# Connect to the Spring Media cluster
gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} --project=${PROJECT_ID} --zone=${CLUSTER_LOCATION}

# Export relevent environment variables
export PROD_ARTIFACT_REGISTRY=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${PROD_CLUSTER_NAME}
export SPRING_BOOKS_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o json | jq -r ".status.loadBalancer.ingress[0].ip")
export SPRING_MUSIC_URL=$(kf apps -o json | jq -r ".items[0].status.urls[0]" | sed "s/.\{1\}$//")

# Spring Music Load Generator
# -------------------------------
cd ~/migrate-kf-anthos-demo/load-generators/spring-music

# Build the Spring Music Load Generator container image and store in Artifact Registry
gcloud builds submit --tag ${PROD_ARTIFACT_REGISTRY}/spring-music-load-generator

# Deploy the Spring Music Load Generator to the cluster
envsubst < spring-music-load-generator.yaml | kubectl apply -f -

# Spring Books Load Generator
# -------------------------------
# Run Siege Load Generator in the background (will continue running if Cloud Shell is closed)
siege http://$SPRING_BOOKS_URL:80/productpage &
