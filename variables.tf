variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to deploy to"
  type        = string
  default     = "us-central1-a"
}

variable "vpc_name" {
  description = "Name of a VPC"
  type        = string
  default     = "my-vpc"
}

variable "private_subnet" {
  description = "Name of a Private Subnet"
  type        = string
  default     = "private-subnet"
}

variable "public_subnet" {
  description = "Name of a Public Subnet"
  type        = string
  default     = "private-subnet"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "autopilot-cluster"
}

variable "master_authorized_cidr_blocks" {
  description = "CIDR block allowed to access the GKE control plane"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vm_name" {
  description = "Name of the MongoDB VM instance"
  type        = string
  default     = "mongodb-server"
}

variable "vm_image" {
  description = "Boot disk image for the MongoDB VM"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "vm_machine_type" {
  description = "Machine type for the MongoDB VM"
  type        = string
  default     = "e2-small"
}

variable "vm_disk_size" {
  description = "Boot disk size in GB for the MongoDB VM"
  type        = number
  default     = 20
}

variable "gar_repository_id" {
  description = "Google Artifact Registry repository ID for Docker images"
  type        = string
  default     = "web-app"
}

variable "wif_pool_id" {
  description = "Workload Identity Federation pool ID (e.g. projects/123/locations/global/workloadIdentityPools/my-pool)"
  type        = string
}

variable "deployer_github_repo" {
  description = "GitHub repository allowed to impersonate the GKE deployer SA (e.g. org/repo-name)"
  type        = string
  default     = "jasaz/web-app"
}

variable "mongo_admin_pass" {
  description = "MongoDB admin user password (set via TF_VAR_mongo_admin_pass)"
  type        = string
  sensitive   = true
}

variable "mongo_app_pass" {
  description = "MongoDB application user password (set via TF_VAR_mongo_app_pass)"
  type        = string
  sensitive   = true
}
