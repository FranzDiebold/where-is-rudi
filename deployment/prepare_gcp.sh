#!/bin/bash

project_id="whereisrudi-<random_number>"
project_name="WhereIsRudi"
service_account_id="$project_id-sa"

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

echo "##########################################################"
echo "You need to enable billing for the newly created project."
echo "(It is needed for the Cloudscheduler API.)"
echo "You can do this here: https://console.cloud.google.com/settings?project=$project_id"
read -p "When you are done with that press [enter] to continue..."

# Enable Google Cloud Platform APIs
apis=(
    "appengine"
    "cloudfunctions"
    "cloudscheduler"
    "datastore"
)
for api in "${apis[@]}"; do
    gcloud services enable "$api.googleapis.com" --project="$project_id"
done
