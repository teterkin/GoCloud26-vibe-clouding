terraform {
  required_providers {
    cloudru = {
      source  = "cloud.ru/cloudru/cloud"
      version = "2.0.0"
    }
  }
}

locals {
  project_id          = var.project_id
  auth_key_id         = var.auth_key_id
  auth_secret         = var.auth_secret
  environment         = var.environment
  vm_name             = "${var.environment}-${var.vm_name}"
  vm_user             = var.vm_user
  vm_password         = var.vm_password != null ? var.vm_password : ""
  vm_password_hash    = var.vm_password_hash != null ? var.vm_password_hash : ""
  ssh_public_key_path = var.ssh_public_key_path
  subnet_address      = var.subnet_address
  vpc_name            = "${var.environment}-${var.vpc_name}"
  disk_size           = var.disk_size
  disk_type           = var.disk_type
  flavor              = var.flavor
  zone                = var.zone
  my_ip               = var.my_ip

  cloud_config = templatefile("${path.module}/cloud-config.tpl", {
    vm_user        = local.vm_user,
    vm_name        = local.vm_name,
    ssh_public_key = file(local.ssh_public_key_path),
    vm_password    = local.vm_password != "" ? local.vm_password : local.vm_password_hash,
    use_password   = local.vm_password != "" || local.vm_password_hash != ""
  })
}

provider "cloudru" {
  project_id  = local.project_id
  auth_key_id = local.auth_key_id
  auth_secret = local.auth_secret

  endpoints = {
    iam_endpoint            = "iam.api.cloud.ru:443"
    compute_endpoint        = "compute.api.cloud.ru:443"
    baremetal_endpoint      = "baremetal.api.cloud.ru:443"
    mk8s_endpoint           = "mk8s.api.cloud.ru:443"
    vpc_endpoint            = "vpc.api.cloud.ru:443"
    magic_router_endpoint   = "magic-router.api.cloud.ru"
    dns_endpoint            = "dns.api.cloud.ru:443"
    nlb_endpoint            = "nlb.api.cloud.ru"
    kafka_endpoint          = "kafka.api.cloud.ru:443"
    redis_endpoint          = "redis.api.cloud.ru:443"
    object_storage_endpoint = "https://s3.cloud.ru"
  }
}

data "cloudru_evolution_compute_image_collection" "ubuntu" {
  project_id = local.project_id
  page_size  = 100
}

resource "cloudru_evolution_vpc_vpc" "vpc" {
  project_id  = local.project_id
  description = "VPC for ${local.environment} environment"
  name        = local.vpc_name
}

resource "cloudru_evolution_compute_disk" "disk" {
  project_id = local.project_id

  name = "${local.environment}-quiz-disk"
  size = local.disk_size

  zone_identifier = {
    name = local.zone
  }

  disk_type_identifier = {
    name = local.disk_type
  }

  description = "Disk for ${local.environment} VM"
  bootable    = true
  image_id    = [for img in data.cloudru_evolution_compute_image_collection.ubuntu.images : img.id if img.name == "ubuntu-22.04"][0]
  encrypted   = false
  readonly    = false
  shared      = false
}

resource "cloudru_evolution_compute_security_group" "sg" {
  project_id = local.project_id

  name = "${local.environment}-quiz-sg"

  zone_identifier = {
    name = local.zone
  }

  description = "Security group for ${local.environment} VM"
}

resource "cloudru_evolution_compute_security_group_rule" "ingress_ssh" {
  security_group_id = cloudru_evolution_compute_security_group.sg.id
  direction         = "TRAFFIC_DIRECTION_INGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "22:22"
  description       = "SSH access from my IP"
  remote_ip_prefix  = local.my_ip
}

resource "cloudru_evolution_compute_security_group_rule" "ingress_http" {
  security_group_id = cloudru_evolution_compute_security_group.sg.id
  direction         = "TRAFFIC_DIRECTION_INGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "80:80"
  description       = "HTTP access from anywhere"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_security_group_rule" "ingress_app" {
  security_group_id = cloudru_evolution_compute_security_group.sg.id
  direction         = "TRAFFIC_DIRECTION_INGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "5000:5000"
  description       = "App port access from anywhere"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_security_group_rule" "ingress_https" {
  security_group_id = cloudru_evolution_compute_security_group.sg.id
  direction         = "TRAFFIC_DIRECTION_INGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "443:443"
  description       = "HTTPS access from anywhere"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_security_group_rule" "egress_tcp" {
  security_group_id = cloudru_evolution_compute_security_group.sg.id
  direction         = "TRAFFIC_DIRECTION_EGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "1:65535"
  description       = "Allow all outgoing TCP"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_security_group_rule" "egress_udp" {
  security_group_id = cloudru_evolution_compute_security_group.sg.id
  direction         = "TRAFFIC_DIRECTION_EGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_UDP"
  port_range        = "1:65535"
  description       = "Allow all outgoing UDP"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_subnet" "subnet" {
  project_id = local.project_id

  name = "${local.environment}-quiz-subnet"

  zone_identifier = {
    name = local.zone
  }

  description    = "Subnet for ${local.environment} VM"
  subnet_address = local.subnet_address
  routed_network = true
  default        = false
  vpc_id         = cloudru_evolution_vpc_vpc.vpc.id

  dns_servers = {
    value = ["8.8.4.4", "8.8.8.8"]
  }
}

resource "cloudru_evolution_compute_interface" "nic" {
  project_id = local.project_id

  name = "${local.environment}-quiz-nic"

  zone_identifier = {
    name = local.zone
  }

  description                = "Network interface for ${local.environment} VM"
  subnet_id                  = cloudru_evolution_compute_subnet.subnet.id
  interface_security_enabled = true

  security_groups_identifiers = {
    value = [{
      id = cloudru_evolution_compute_security_group.sg.id
    }]
  }

  external_ip_specs = {
    new_external_ip = true
  }

  type = "INTERFACE_TYPE_REGULAR"
}

resource "cloudru_evolution_compute_vm" "vm" {
  project_id = local.project_id

  name = local.vm_name

  zone_identifier = {
    name = local.zone
  }

  flavor_identifier = {
    name = local.flavor
  }

  description = "VM for ${local.environment} environment"

  disk_identifiers = [{
    disk_id = cloudru_evolution_compute_disk.disk.id
  }]

  network_interfaces = [{
    interface_id = cloudru_evolution_compute_interface.nic.id
  }]

  cloud_init_userdata = base64encode(local.cloud_config)
}

output "vm_id" {
  description = "Virtual machine ID"
  value       = cloudru_evolution_compute_vm.vm.id
}

output "vm_name" {
  description = "Virtual machine name"
  value       = cloudru_evolution_compute_vm.vm.name
}

output "vm_internal_ip" {
  description = "Internal IP address"
  value       = cloudru_evolution_compute_interface.nic.ip_address
}

output "external_ip" {
  description = "External IP address"
  value       = cloudru_evolution_compute_interface.nic.external_ip.ip_address
}

output "vm_user" {
  description = "VM user"
  value       = local.vm_user
}

output "environment" {
  description = "Environment"
  value       = local.environment
}

output "zone" {
  description = "Availability zone"
  value       = local.zone
}
