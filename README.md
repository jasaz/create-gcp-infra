# GKE Autopilot Deployment with Terraform and Workload Identity Federation

This repository contains following Terraform code:

1. networking.tf - VPC, Private & Public Subnet, Router, NAT
2. k8s.tf - GKE Autopilot
3. artifact-registry.tf - Google Artifact Registry (GAR)
3. vm.tf - GCE Instance with MongoDB 6.0, Reserved Internal Address
4. vm_resources.tf - GCS Bucket for MongoDB backup, GCE SA for VM, permissions for VM SA
5. firewall.tf - Firewall for Public SSH access to GCE & GKE Pod access to GCE 
5. app-deployer.sh - Create SA for app deployment for the repo - deploy-webapp with necessary permissions

## Prerequisites

1.  **Google Cloud Project**: GCP project.
2.  **GCS Bucket**: GCS bucket for store the Terraform state.
    *   Update `main.tf` with your bucket name: `bucket = "YOUR_BUCKET_NAME"`
3.  **Terraform**: For Infra Deployment

## Bootstrap Instructions (One-Time Setup)

The following code must be executed before the Pipeline is run.

```
export PROJECT_ID={GCP-PROJECT-ID}
export GITHUB_SA={WORKLOAD-IDENTIFIER-SA-NAME}
export BUCKET_NAME={BUCKET-NAME}
export PROJECT_NUMBER={GCP-PROJECT-NUMBER}
export LOCATION={GCP-REGION}

gcloud config set project ${PROJECT_ID}
```

### Enable the APIs
```
gcloud services enable compute.googleapis.com \
  artifactregistry.googleapis.com \
  container.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  storage.googleapis.com \
  --project=${PROJECT_ID}
```

### Create a Service account for Workload Identifier.
```
gcloud iam service-accounts create ${GITHUB_SA} \
  --project "${PROJECT_ID}" 
```

### Create a Workload Identity Pool for Github.
```
gcloud iam workload-identity-pools create "github-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"
```

### Get the ID of the Workload Identity Pool
```
WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe "github-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)")
```

### Get the Github REPO Id. This will be used to restrict the OIDC Token for the below repos. Replace the repo name with your repos and Bearer token
```
TF_REPO="jasaz/create-gcp-infra"
APP_REPO="jasaz/deploy-webapp"

OWNER_ID=$(curl -sfL -H "Accept: application/json" -H "Authorization: Bearer {Your-Bearer-Token}" "https://api.github.com/repos/${TF_REPO}" | jq .owner.id) 
TF_REPO_ID=$(curl -sfL -H "Accept: application/json" -H "Authorization: Bearer {Your-Bearer-Token}" "https://api.github.com/repos/${TF_REPO}" | jq .id)
APP_REPO_ID=$(curl -sfL -H "Accept: application/json" -H "Authorization: Bearer {Your-Bearer-Token}" "https://api.github.com/repos/${APP_REPO}" | jq .id)
```

### Create a GitHub Workload Identity Provider for both Terraform Repo and App Repo mentioned above. Restrict access to Tokens using Owner Id and Repo Id.
```
gcloud iam workload-identity-pools providers create-oidc "gh-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub repo Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository=assertion.repository,attribute.repository_id=assertion.repository_id,attribute.repository_owner_id=assertion.repository_owner_id" \ 
  --attribute-condition="assertion.repository_owner_id == '${OWNER_ID}' &&  (assertion.repository_id == '${TF_REPO_ID}' || assertion.repository_id == '${APP_REPO_ID}') "  \
  --issuer-uri="https://token.actions.githubusercontent.com"
```
### Extract the Workload Identity Provider resource name. Remove provider/provider name from the above path at the end
```
gcloud iam workload-identity-pools providers describe "gh-provider"   --project="${PROJECT_ID}"   --location="global"   --workload-identity-pool="github-pool"   --format="value(name)"
```
```
gcloud iam service-accounts add-iam-policy-binding "${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${TF_REPO}"
```
```			               
gcloud iam service-accounts add-iam-policy-binding "${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${APP_REPO}"
```

### Create Bucket for Storing TF State File
```
gcloud storage buckets create gs://${BUCKET_NAME}  --location=${LOCATION}
```

### Project Level access for the Github Service Account
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/storage.admin"
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/container.admin"
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/compute.instanceAdmin.v1"
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/compute.securityAdmin"
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/resourcemanager.projectIamAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${GITHUB_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/iam.serviceAccountAdmin"
```
## Secrets

Following secrets must be configured in the Github Repo

- GCP_PROJECT_ID - Google Cloud Project ID
- TFSTATE_GCS_BUCKET - GCS Bucket where the Terraform State file will be stored
- WIF_POOL_ID - Workload Identity Pool ID 
- WIF_PROVIDER - Workload Identity Provider
- WIF_SERVICE_ACCOUNT - Service Account associated with Github SA
- MONGO_ADMIN_PASS - Password for MOngoDB admin database
- MONGO_APP_PASS - Password for MongoDB flask database 

## Automated Deployment

Once the secrets are set, any push to the `main` branch will trigger the workflow in `.github/workflows/deploy.yml`, which will:
1.  Authenticate using WIF.
2.  Plan and Apply changes to your GCP Project.
