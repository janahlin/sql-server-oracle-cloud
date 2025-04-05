# Architecture for SQL Server Developer Edition in Oracle Cloud

This document describes the architecture for SQL Server Developer Edition in Oracle Cloud Free Tier.

## Overview

The architecture consists of the following components:

1. **Windows Server 2019 VM** in Oracle Cloud Free Tier
   - 2 OCPU (ARM64)
   - 8 GB RAM
   - 100 GB storage

2. **SQL Server Developer Edition**
   - Installed on Windows Server 2019
   - Configured for optimal performance in development environment

3. **Controller VM**
   - Used to run Terraform and Ansible
   - Manages deployment of infrastructure and configuration

## Resource Allocation

Oracle Cloud Free Tier offers the following resources:
- 4 OCPU (ARM64)
- 24 GB RAM
- 200 GB Block Storage (2 volumes)

In this architecture, the following is used:
- 2 OCPU (50%)
- 8 GB RAM (33%)
- 100 GB Block Storage (50%)

This leaves sufficient resources to run other services in Oracle Cloud Free Tier.

## Network Architecture

- Windows Server VM has a public IP address for remote access
- SQL Server is configured to listen on TCP/IP for remote connections
- WinRM is configured for Ansible connections

## Security

- Windows Server is configured with Windows Defender
- SQL Server is configured with Windows authentication
- Network security is managed via Oracle Cloud Security Lists

## Infrastructure as Code

The architecture is implemented using Infrastructure as Code (IaC) principles:

1. **Terraform** is used to provision the infrastructure:
   - Virtual Cloud Network (VCN)
   - Internet Gateway
   - Security Lists
   - Subnet
   - Windows VM
   - Storage Volume

2. **Ansible** is used to configure the Windows VM and SQL Server:
   - WinRM configuration
   - Disk configuration
   - SQL Server installation
   - SQL Server configuration

## Diagram
