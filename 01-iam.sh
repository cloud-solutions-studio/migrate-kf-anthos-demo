#!/bin/bash

# Allow the cluster service account to modify its own policy. The Kf controller will use this to add new (name)spaces to the policy, allowing reuse for Workload Identity.
gcloud iam service-accounts add-iam-policy-binding ${CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=${PROJECT_ID} \
  --role="roles/iam.serviceAccountAdmin" \
--member="serviceAccount:${CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Give the cluster service account role to read/write from GCR
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member="serviceAccount:${CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/storage.admin"

# Give the cluster service account monitoring metrics role for write access to Cloud Monitoring
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

# Associate the cluster's identity namespace with the cluster.
gcloud iam service-accounts add-iam-policy-binding \
    "${CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project=${PROJECT_ID} \
    --role="roles/iam.workloadIdentityUser" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[kf/controller]"

# Grant the cluster service account permission on the Artifact Registry repository
gcloud beta artifacts repositories add-iam-policy-binding ${CLUSTER_NAME} \
  --location=${COMPUTE_REGION} \
  --member="serviceAccount:${CLUSTER_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Configure Docker to use the gcloud command-line tool to authenticate requests to Artifact Registry.
gcloud auth configure-docker ${COMPUTE_REGION}-docker.pkg.dev

# Create an environment variable for the Connect service account that will register the cluster to the environ.
export CONNECT_SERVICE_ACCOUNT=${CLUSTER_NAME}-connect

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