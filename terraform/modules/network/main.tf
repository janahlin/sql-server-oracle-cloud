terraform {
  required_version = ">= 1.0.0"
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.0.0"
    }
  }
}

variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
}

variable "vcn_name" {
  description = "Name of the VCN"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

# Create a Virtual Cloud Network (VCN)
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  display_name   = var.vcn_name
  cidr_block     = var.vcn_cidr
  dns_label      = "sqlvcn"
}

# Create an Internet Gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  display_name   = "${var.vcn_name}-igw"
  vcn_id         = oci_core_vcn.vcn.id
}

# Create a Route Table
resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_name}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

# Create a Security List
resource "oci_core_security_list" "security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_name}-sl"

  # Allow RDP connections from anywhere
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 3389
      max = 3389
    }
  }

  # Allow WinRM connections from anywhere
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 5985
      max = 5986
    }
  }

  # Allow SQL Server access
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 1433
      max = 1433
    }
  }

  # Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

# Subnet
resource "oci_core_subnet" "subnet" {
  compartment_id = var.compartment_id
  display_name   = "${var.vcn_name}-subnet"
  vcn_id         = oci_core_vcn.vcn.id
  cidr_block     = cidrsubnet(var.vcn_cidr, 8, 1)
  route_table_id = oci_core_route_table.route_table.id
  security_list_ids = [
    oci_core_security_list.security_list.id
  ]
  dns_label = "sqlserversub"
}

output "vcn_id" {
  value = oci_core_vcn.vcn.id
}

output "subnet_id" {
  value = oci_core_subnet.subnet.id
}
