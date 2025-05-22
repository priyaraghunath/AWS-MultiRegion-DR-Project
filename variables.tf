variable "region1" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "region2" {
  description = "Secondary AWS region"
  type        = string
  default     = "us-west-2"
}

variable "bucket_prefix" {
  description = "Prefix for S3 bucket names"
  type        = string
  default     = "multi-region-app"
}

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "multi-region-db"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for Route 53"
  type        = string
  default     = "example.com"
}
