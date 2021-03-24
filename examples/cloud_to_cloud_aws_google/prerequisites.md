# Megaport Terraform Requirements

This document covers the preparation tasks and requirements to support a multicloud architecture with Megaport.


Getting started: https://registry.terraform.io/providers/megaport/megaport/latest/docs/guides/gettingstarted


# GCP Setup

The Megaport Terraform provider requires a GCP service account to setup and provision resources.

## Set ENV Vars

```shell
export PROJECT_ID="poc-megaport"
export PROJECT_NAME="Megaport POC"
export SERVICE_ACCT_ID="megaport-sa"
export SERVICE_ACCT_NAME="Megaport POC Service Account"
export $SERVICE_ACCT_ID@$PROJECT_ID.iam.gserviceaccount.com
```

## Create Project

```shell
gcloud projects create $PROJECT_ID --name=$PROJECT_NAME
```

```
Create in progress for [https://cloudresourcemanager.googleapis.com/v1/projects/poc-megaport].
Waiting for [operations/cp.6537659165377592124] to finish...done.
Enabling service [cloudapis.googleapis.com] on project [poc-megaport]...
Operation "operations/acf.p2-1063870521684-5d5d39a6-3727-42d6-91a5-58d5af38d6ac" finished successfully.
```

## Switch Project

```shell
gcloud config set project $PROJECT_ID
```

## Create Service Account

```shell
gcloud iam service-accounts create $SERVICE_ACCT_ID \
    --display-name "$SERVICE_ACCT_NAME" \
    --description="$SERVICE_ACCT_NAME" \
    --project $PROJECT_ID
```

```
Created service account [megaport-sa].
```

## Add IAM Roles to Service Account

```shell
gcloud iam service-accounts add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCT_ID@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"
```

```shell
gcloud iam service-accounts add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:megaport-sa@poc-megaport.iam.gserviceaccount.com" \
    --role="roles/iam.owner"
```

# Authentication

* Use Megaport portal username and password
or
* Use Megaport MFA OTP Key