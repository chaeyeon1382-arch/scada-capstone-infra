variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
  default     = "project-52d3e61e-2e0d-4571-935"
}

variable "region" {
  description = "GCP 리전"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP 존"
  type        = string
  default     = "asia-northeast3-a"
}

variable "vm_deploy_key" {
  description = "VM용 GitHub 배포 키"
  type        = string
  sensitive   = true
}