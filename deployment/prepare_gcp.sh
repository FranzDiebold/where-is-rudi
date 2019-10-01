#!/bin/bash

project_id="whereisrudi-test"
project_name="WhereIsRudi"
service_account_id="test3-sa"

service_account_email="$service_account_id@$project_id.iam.gserviceaccount.com"

# Google Cloud Platform project
gcloud projects create "$project_id" --name="$project_name"

# Google IAM Service account
gcloud iam service-accounts create "$service_account_id" --display-name="$service_account_id" --project="$project_id"
roles=(
    "roles/owner"
    "roles/iam.serviceAccountUser"
    "roles/storage.admin"
    "roles/appengine.appAdmin"
    "roles/cloudscheduler.admin"
    "roles/cloudfunctions.developer"
    "roles/pubsub.editor"
)
for role in "${roles[@]}"; do
    gcloud projects add-iam-policy-binding "$project_id" --member="serviceAccount:$service_account_email" --role="$role"
done
gcloud iam service-accounts keys create --iam-account="$service_account_email" account.json

# Enable Google Cloud Platform APIs
apis=(
    "appengine"
    "cloudfunctions"
    "cloudscheduler"
)
for api in "${apis[@]}"; do
    gcloud services enable cloudresourcemanager.googleapis.com --project="$project_id"
done