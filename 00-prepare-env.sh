#!/bin/bash

sudo apt-get update && sudo apt-get install -y google-cloud-sdk-kpt

gcloud config set project ${PROJECT_ID}
gcloud config set compute/zone ${CLUSTER_LOCATION}

gcloud services enable \
    --project=${PROJECT_ID} \
    container.googleapis.com \
    compute.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com \
    cloudtrace.googleapis.com \
    meshca.googleapis.com \
    meshtelemetry.googleapis.com \
    meshconfig.googleapis.com \
    iamcredentials.googleapis.com \
    gkeconnect.googleapis.com \
    gkehub.googleapis.com \
    cloudresourcemanager.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com