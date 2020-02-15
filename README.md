# WhereIsRudi :dog:

[![app:slack](https://img.shields.io/badge/app-Slack-611f69.svg)](https://slack.com)
[![technology: Google Cloud Platform](https://img.shields.io/badge/technology-Google_Cloud_Platform-1a73e8.svg)](https://cloud.google.com)
[![IaC: Terraform](https://img.shields.io/badge/IaC-Terraform-5c4ee5.svg)](./deployment/main.tf)
[![Lint Status](https://github.com/FranzDiebold/where-is-rudi/workflows/Lint/badge.svg?branch=master)](https://github.com/FranzDiebold/where-is-rudi/actions?query=workflow%3A%22Lint%22)
[![license: MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg)](./LICENSE.md)

<img src="./design/WhereIsRudi_logo.png" width="300px">

*WhereIsRudi* is an interactive [Slack](https://slack.com) app to inform your colleagues whether your dog@work is in the office today! :tada:


## Usage

### Colleagues

![Slack Example Colleagues](./images/slack-example-colleagues.gif)

Use the [Slash Command](https://api.slack.com/slash-commands) `\whereisrudi` in any channel, direct message or any other slack conversation. That's it!

### Dog Owner

![Slack Example Dog Owner](./images/slack-example-dog-owner.png)

You will get a message every (working day) morning to ask you whether you bring your dog to the office today. Just answer with one tap or click via the actions in the message. It's that easy!


## Architecture & Sequence

![WhereIsRudi architecture](./images/WhereIsRudi_architecture.jpg)


## Installation/Deployment

For easier deployment, the *infrastructure as code* (IaC) software tool [Terraform](https://www.terraform.io/) is used.

#### Preparations

1. Install Terraform: [https://learn.hashicorp.com/terraform/getting-started/install.html](https://learn.hashicorp.com/terraform/getting-started/install.html)
2. Define a Google Cloud Platform (GCP) project id, i.e. `whereisrudi-<random_number>` and enter it in:
    - [`deployment/prepare_gcp.sh`](./deployment/prepare_gcp.sh)
    - [`deployment/variables.tf`](./deployment/variables.tf)
3. Run preparation script:
    1. Run `prepare_gcp.sh`: `bash prepare_gcp.sh`. You may run this in the [Google Cloud Shell editor](https://ssh.cloud.google.com/cloudshell/editor). This will:
        - Create a Google Cloud Platform project.
        - Create Service Account and bind the roles `roles/owner`, `roles/iam.serviceAccountUser`, `roles/storage.admin`, `roles/appengine.appAdmin`, `roles/cloudscheduler.admin`, `roles/pubsub.editor` and `roles/cloudfunctions.developer`.
        - Create new private key for the Service Account and save in the file `account.json`.
        - Enable the Google Cloud Platform APIs `appengine`, `cloudfunctions`, `cloudscheduler` and `datastore`.
        - You will be asked to enable billing for the created project when running the script.
    2. Copy the file `account.json` into the `deployment` folder.

#### Deployment

1. Commands need to be run in `deployment` folder: `cd /deployment`
2. Initialize the Terraform working directory: `terraform init`
3. Generate and show the Terraform execution plan: `terraform plan`
4. Build the infrastructure: `terraform apply` and confirm with `yes`. This step will output the endpoint URLs `slack_actions_function_url` and `slack_slash_commands_function_url` that you need to enter in the Slack API console.

To destroy/delete the infrastructure: `terraform destroy` and confirm with `yes`

### Google Cloud Platform Resources

The following [Google Cloud Platform](https://console.cloud.google.com) resources are created via Terraform:

#### Google Cloud Function

![Google Cloud Functions](./images/google-cloud-functions.png)

Three cloud functions with environment variables:
- `gather-information` (triggered by Google Pub/Sub topic `gather-information-schedule`)
    - `SLACK_API_TOKEN`: Slack App *OAuth Access Token* (starting with `xoxp-`)
    - `USER_ID`: Slack user id of dog owner.
- `slack-actions` (triggered by HTTP)
    - `SLACK_API_VERIFICATION_TOKEN`: Slack App Verification Token
- `slack-slash-commands` (triggered by HTTP)
    - `SLACK_API_VERIFICATION_TOKEN`: Slack App Verification Token

#### Google Cloud Scheduler

![Google Cloud Scheduler](./images/google-cloud-scheduler.png)

Google Pub/Sub topic `gather-information-schedule` should be triggered every working day (monday - friday) at 7:30 AM.

Therefore the frequency is set to `30 7 * * 1-5`.

#### Google Cloud Datastore / Google Cloud Firestore Datastore Mode

![Google Cloud Datastore](./images/google-cloud-datastore.png)

The cloud functions create a entities of kind `days`. The entity id is the day string (i.e. `2019-09-14`). The entities only have one boolean field `in_office`, which is not indexed.

### Slack API/App

#### Slack App

Create a new Slack app in the Slack API console: [https://api.slack.com/apps](https://api.slack.com/apps).

#### Bot User

![Slack API Bot User](./images/slack-api-bot-user.png)

Create a Bot User, i.e. `WhereIsRudi`.

#### OAuth & Permissions

![Slack API Permissions](./images/slack-api-permissions.png)

In OAuth & Permissions in Scopes, add permission scope `chat:write:bot` and `incoming-webhook` to *Conversations* and `bot` and `commands` to *Interactivity*.

#### Interactive Components

![Slack API Actions](./images/slack-api-actions.png)

Add Interactivity request URL pointing to your Google Cloud Function `slack-actions`. You got this URL as output from the `terraform apply` step before, named `slack_actions_function_url`.

#### Slash Commands

![Slack API Slash Commands 1](./images/slack-api-slash-commands-1.png)

![Slack API Slash Commands 2](./images/slack-api-slash-commands-2.png)

Create new Slash command `/whereisrudi` with request URL pointing to your Google Cloud Function `slack-slash-commands`. You got this URL as output from the `terraform apply` step before, named `slack_slash_commands_function_url`.


## Design

See [/design](./design/).
