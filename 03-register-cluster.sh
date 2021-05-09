#!/bin/bash

# Spring Media Production Cluster
# -------------------------------
# Create an environment variable for the URI of the Spring Media Production cluster
export PROD_CLUSTER_URI=$(gcloud container clusters list --project=${PROJECT_ID} --uri | sed -n 2p)

# Create an environment variable for the Connect service account that will register the cluster to the environ.
export PROD_CONNECT_SERVICE_ACCOUNT=${PROD_CLUSTER_NAME}-connect

# Create an environment variable for the local filepath where the Connect service account's private key JSON file is saved.
export PROD_SERVICE_ACCOUNT_KEY_PATH=/tmp/creds/${PROD_CONNECT_SERVICE_ACCOUNT}-${PROJECT_ID}.json

# Register the cluster
gcloud container hub memberships register ${PROD_CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --gke-uri=${PROD_CLUSTER_URI} \
    --service-account-key-file=${PROD_SERVICE_ACCOUNT_KEY_PATH}

# Spring Media Development Cluster
# -------------------------------
# Create an environment variable for the URI of the Spring Media Development cluster
export DEV_CLUSTER_URI=$(gcloud container clusters list --project=${PROJECT_ID} --uri | sed -n 1p)

# Create an environment variable for the Connect service account that will register the cluster to the environ.
export DEV_CONNECT_SERVICE_ACCOUNT=${DEV_CLUSTER_NAME}-connect

# Create an environment variable for the local filepath where the Connect service account's private key JSON file is saved.
export DEV_SERVICE_ACCOUNT_KEY_PATH=/tmp/creds/${DEV_CONNECT_SERVICE_ACCOUNT}-${PROJECT_ID}.json

# Register the cluster
gcloud container hub memberships register ${DEV_CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --gke-uri=${DEV_CLUSTER_URI} \
    --service-account-key-file=${DEV_SERVICE_ACCOUNT_KEY_PATH}