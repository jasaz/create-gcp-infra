# GKE Autopilot Deployment with Terraform and Workload Identity Federation

This repository contains Terraform code to deploy a GKE Autopilot cluster and a GitHub Actions workflow for automated deployment.

## Prerequisites

1.  **Google Cloud Project**: You need a GCP project.
2.  **GCS Bucket**: Create a GCS bucket to store the Terraform state.
    *   Update `main.tf` with your bucket name: `bucket = "YOUR_BUCKET_NAME"`
3.  **GCP SDK**: Ensure you have the `gcloud` CLI installed and authenticated.
4.  **Terraform**: Ensure you have Terraform installed.

## Bootstrap Instructions (One-Time Setup)

To enable GitHub Actions to deploy to your GCP project, you must first create the Workload Identity Federation (WIF) resources and Service Account. This must be done locally once.

1.  **Authenticate Locally**:
    ```bash
    gcloud auth application-default login
    ```

2.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

3.  **Apply and Create Resources**:
    You can create everything at once, or target just the IAM resources first.
    Replace the placeholders with your values.

    ```bash
    terraform apply -var="project_id=YOUR_PROJECT_ID" \
                -var="service_account_email=YOUR_SA_EMAIL"
    ```

4.  **Get Output Values**:
    After a successful apply, Terraform will output the necessary values:
    ```bash
    terraform output
    ```
    Note the values for `workload_identity_provider` and `service_account_email`.

## GitHub Configuration

1.  Go to your GitHub Repository -> **Settings** -> **Secrets and variables** -> **Actions**.
2.  Create the following **Repository Secrets**:
    *   `WIF_PROVIDER`: The value of `workload_identity_provider` from the Terraform output.
        *   (e.g., `projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider`)
    *   `WIF_SERVICE_ACCOUNT`: The value of `service_account_email` from the Terraform output.
        *   (e.g., `github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com`)

## Automated Deployment

Once the secrets are set, any push to the `main` branch will trigger the workflow in `.github/workflows/deploy.yml`, which will:
1.  Authenticate using WIF.
2.  Plan and Apply changes to your GKE cluster.
