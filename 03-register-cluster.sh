#!/bin/bash

# Spring Media Production Cluster
# -------------------------------
# Create an environment variable for the URI of the Spring Media cluster
export CLUSTER_URI=$(gcloud container clusters list --project=${PROJECT_ID} --uri | sed -n 2p)

# Create an environment variable for the Connect service account that will register the cluster to the environ.
export CONNECT_SERVICE_ACCOUNT=${PROD_CLUSTER_NAME}-connect

# Create an environment variable for the local filepath where the Connect service account's private key JSON file is saved.
export SERVICE_ACCOUNT_KEY_PATH=/tmp/creds/${CONNECT_SERVICE_ACCOUNT}-${PROJECT_ID}.json

# Register the cluster
gcloud container hub memberships register ${PROD_CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --gke-uri=${CLUSTER_URI} \
    --service-account-key-file=${SERVICE_ACCOUNT_KEY_PATH}
