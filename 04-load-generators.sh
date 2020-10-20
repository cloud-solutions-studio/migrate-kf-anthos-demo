# Export relevent environment variables
export ARTIFACT_REGISTRY=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${CLUSTER_NAME}
export SPRING_BOOKS_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o json | jq -r ".status.loadBalancer.ingress[0].ip")
export SPRING_MUSIC_URL=$(kf apps -o json | jq -r ".items[0].status.urls[0]")

# Connect to the Spring Media cluster
gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_LOCATION}

# Deploy the Spring Music Load Generator
cd ~/migrate-kf-anthos-demo/load-generators/spring-music

# Build the Spring Music Load Generator container image and store in Artifact Registry
gcloud builds submit --tag ${ARTIFACT_REGISTRY}/spring-music-load-generator

# Deploy the Spring Music Load Generator to the cluster
envsubst < spring-music-load-generator.yaml | kubectl apply -f -


