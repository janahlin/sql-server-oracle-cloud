# Architecture for SQL Server Developer Edition in Azure

This document describes the architecture for SQL Server Developer Edition in Microsoft Azure.

## Overview

The architecture consists of the following components:

1. **Windows Server 2019 VM** in Azure
   - Standard_B1s (1 vCPU, 1 GB RAM)
   - 100 GB storage

2. **SQL Server Developer Edition**
   - Installed on Windows Server 2019
   - Configured for optimal performance in development environment

3. **Controller Machine**
   - Used to run Terraform and Ansible
   - Manages deployment of infrastructure and configuration

## Resource Allocation

The Azure Standard_B1s VM is a cost-effective option for development purposes:
- 1 vCPU
- 1 GB RAM
- 100 GB disk space

This provides sufficient resources to run SQL Server Developer Edition for development and testing while keeping costs low.

## Network Architecture

- Virtual Network (VNet) with a subnet for the Windows VM
- Network Security Group (NSG) with rules allowing:
  - RDP (TCP 3389) for remote desktop access
  - WinRM (TCP 5985/5986) for Ansible connections
  - SQL Server (TCP 1433) for database connections
- Windows VM with a public IP address for remote access

## Security

- Windows Server is configured with Windows Defender
- SQL Server is configured with Windows authentication
- Network security is managed via Azure Network Security Groups
- Use of Azure Key Vault is recommended for storing secrets (not implemented in this basic version)

## Infrastructure as Code

The architecture is implemented using Infrastructure as Code (IaC) principles:

1. **Terraform** is used to provision the infrastructure:
   - Resource Group
   - Virtual Network
   - Network Security Group
   - Subnet
   - Windows VM
   - Storage Disks

2. **Ansible** is used to configure the Windows VM and SQL Server:
   - WinRM configuration
   - Disk configuration
   - SQL Server installation
   - SQL Server configuration

## Diagram
