#!/bin/bash

# Spring Media Production Cluster
# -------------------------------
# Allow the cluster service account to modify its own policy. The Kf controller will use this to add new (name)spaces to the policy, allowing reuse for Workload Identity.
gcloud iam service-accounts add-iam-policy-binding ${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=${PROJECT_ID} \
  --role="roles/iam.serviceAccountAdmin" \
--member="serviceAccount:${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Give the cluster service account role to read/write from GCR
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member="serviceAccount:${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/storage.admin"

# Give the cluster service account monitoring metrics role for write access to Cloud Monitoring
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

# Give the cluster service account logging writer role for write access to Cloud Logging
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

# Give the cluster service account error reporting writer role for write access to Cloud Error Reporting
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/errorreporting.writer"

# Associate the cluster's identity namespace with the cluster.
gcloud iam service-accounts add-iam-policy-binding \
    "${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project=${PROJECT_ID} \
    --role="roles/iam.workloadIdentityUser" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[kf/controller]"

# Grant the cluster service account permission on the Artifact Registry repository
gcloud beta artifacts repositories add-iam-policy-binding ${PROD_CLUSTER_NAME} \
  --location=${COMPUTE_REGION} \
  --member="serviceAccount:${PROD_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Spring Media Development Cluster
# -------------------------------
# Allow the cluster service account to modify its own policy. The Kf controller will use this to add new (name)spaces to the policy, allowing reuse for Workload Identity.
gcloud iam service-accounts add-iam-policy-binding ${DEV_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=${PROJECT_ID} \
  --role="roles/iam.serviceAccountAdmin" \
--member="serviceAccount:${DEV_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Give the cluster service account role to read/write from GCR
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member="serviceAccount:${DEV_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/storage.admin"

# Give the cluster service account monitoring metrics role for write access to Cloud Monitoring
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${DEV_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

# Give the cluster service account logging writer role for write access to Cloud Logging
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${DEV_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

# Give the cluster service account error reporting writer role for write access to Cloud Error Reporting
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${DEV_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/errorreporting.writer"

# Associate the cluster's identity namespace with the cluster.
gcloud iam service-accounts add-iam-policy-binding \
    "${DEV_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project=${PROJECT_ID} \
    --role="roles/iam.workloadIdentityUser" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[kf/controller]"

# Grant the cluster service account permission on the Artifact Registry repository
gcloud beta artifacts repositories add-iam-policy-binding ${DEV_CLUSTER_NAME} \
  --location=${COMPUTE_REGION} \
  --member="serviceAccount:${DEV_CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# -------------------------------
# Configure Docker to use the gcloud command-line tool to authenticate requests to Artifact Registry.
gcloud auth configure-docker ${COMPUTE_REGION}-docker.pkg.dev

# -------------------------------
# Create an environment variable for the Connect service account that will register the cluster to the environ.
export CONNECT_SERVICE_ACCOUNT=${PROD_CLUSTER_NAME}-connect

# Bind the gkehub.connect IAM role to the Connect service account
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${CONNECT_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/gkehub.connect"

# Create an environment variable for the local filepath where you want to save the Connect service account's private key JSON file.
export SERVICE_ACCOUNT_KEY_PATH=/tmp/creds/${CONNECT_SERVICE_ACCOUNT}-${PROJECT_ID}.json

# Download the Connect service account's private key JSON file.
gcloud iam service-accounts keys create ${SERVICE_ACCOUNT_KEY_PATH} \
    --project=${PROJECT_ID} \
    --iam-account=${CONNECT_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com

# Spring Books Application Workload Identity
# -------------------------------
# Configure kubectl command line access
gcloud container clusters get-credentials ${PROD_CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --zone=${CLUSTER_LOCATION}

# Spring Books Details Service Account
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[spring-books/spring-books-details]" \
  spring-books-details@${PROJECT_ID}.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-details@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-details@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudtrace.agent"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-details@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-details@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/errorreporting.writer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-details@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Spring Books Ratings Service Account
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[spring-books/spring-books-ratings]" \
  spring-books-ratings@${PROJECT_ID}.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-ratings@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-ratings@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudtrace.agent"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-ratings@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-ratings@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/errorreporting.writer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-ratings@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Spring Books Reviews Service Account
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[spring-books/spring-books-reviews]" \
  spring-books-reviews@${PROJECT_ID}.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-reviews@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-reviews@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudtrace.agent"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-reviews@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-reviews@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/errorreporting.writer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-reviews@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Spring Books Product Page Service Account
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[spring-books/spring-books-productpage]" \
  spring-books-productpage@${PROJECT_ID}.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-productpage@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-productpage@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudtrace.agent"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-productpage@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-productpage@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/errorreporting.writer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-books-productpage@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Spring Media Load Generator Service Account
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[default/spring-media-load-generator]" \
  spring-media-load-generator@${PROJECT_ID}.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-media-load-generator@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-media-load-generator@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudtrace.agent"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-media-load-generator@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-media-load-generator@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/errorreporting.writer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:spring-media-load-generator@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
