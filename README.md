# WhereIsRudi :dog:

*WhereIsRudi* is an interactive [Slack](https://slack.com) app to inform your colleagues whether your dog@work is in the office today! :tada:

[![app:slack](https://img.shields.io/badge/app-Slack-611f69.svg)](https://slack.com)
[![technology: Google Cloud Platform](https://img.shields.io/badge/technology-Google_Cloud_Platform-1a73e8.svg)](https://cloud.google.com)
[![license: MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg)](./LICENSE.md)

## Usage

### Colleagues

Use the [Slash Command](https://api.slack.com/slash-commands) `\whereisrudi` in any channel, direct message or any other slack conversation. That's it!

### Dog Owner

You will get a message every (working day) morning to ask you whether you bring your dog to the office today. Just answer with one tap or click via the actions in the message. It's that easy!

## Architecture & Sequence

![WhereIsRudi architecture](./images/WhereIsRudi_architecture.jpg)


## Installation

### Google Cloud Platform

In [Google Cloud Platform console](https://console.cloud.google.com) configure the following:

#### Google Cloud Function

![Google Cloud Functions](./images/google-cloud-functions.png)

Create the three cloud functions with environment variables:
- `gather-information` (triggered by Google Pub/Sub topic `gather-information-schedule`)
    - `SLACK_API_TOKEN`: Slack App *OAuth Access Token* (starting with `xoxp-`)
    - `USER_ID`: Slack user id of dog owner.
- `slack-actions` (triggered by HTTP)
    - `SLACK_API_VERIFICATION_TOKEN`: Slack App Verification Token
- `slack-slash-commands` (triggered by HTTP)
    - `SLACK_API_VERIFICATION_TOKEN`: Slack App Verification Token

#### Google Cloud Firestore

![Google Cloud Firestore](./images/google-cloud-firestore.png)

Create a collection called `days`. The documents' id is the day string (i.e. `2019-09-14`). The documents only have one boolean field `in_office`.

#### Google Cloud Scheduler

![Google Cloud Scheduler](./images/google-cloud-scheduler.png)

Google Pub/Sub topic `gather-information-schedule` should be triggered every working day (monday - friday) at 7:30 AM.

Therefore the frequency should be set to `30 7 * * 1-5`.

### Slack API/App

#### Slack App

Create a new Slack app ([https://api.slack.com/apps](https://api.slack.com/apps)).

#### Bot User

Create a Bot User, i.e. `WhereIsRudi`.

#### OAuth & Permissions

In OAuth & Permissions in Scopes, add permission scope `chat:write:bot` and `incoming-webhook` to *Conversations* and `bot` and `commands` to *Interactivity*.

#### Interactive Components

Add Interactivity request URL pointing to your Google Cloud Function `slack-actions`.

#### Slash Commands

Create new Slash command `/whereisrudi` with request URL pointing to your Google Cloud Function `slack-slash-commands`, i.e. `https://europe-west1-<your-project-name>.cloudfunctions.net/<your-function-name>`.
