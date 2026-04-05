variable "project_id" {
  description = "Cloud.ru project ID"
  type        = string
}

variable "auth_key_id" {
  description = "Cloud.ru API key ID"
  type        = string
  sensitive   = true
}

variable "auth_secret" {
  description = "Cloud.ru API secret"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (test/prod)"
  type        = string
  default     = "test"
}

variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "quiz-vm"
}

variable "vm_user" {
  description = "VM user"
  type        = string
  default     = "ubuntu"
}

variable "vm_password" {
  description = "VM password (plain text - will be hashed)"
  type        = string
  default     = null
}

variable "vm_password_hash" {
  description = "Hashed VM password (optional - leave empty to use SSH key only)"
  type        = string
  default     = null
}

variable "flavor" {
  description = "VM flavor"
  type        = string
  default     = "gen-1-1"
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru.AZ-1"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Disk type"
  type        = string
  default     = "SSD"
}

variable "my_ip" {
  description = "Your IP for SSH access"
  type        = string
  default     = "0.0.0.0/32"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "subnet_address" {
  description = "Subnet CIDR"
  type        = string
  default     = "192.168.1.0/24"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "quiz-vpc"
}
