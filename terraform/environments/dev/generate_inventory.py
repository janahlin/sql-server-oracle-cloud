#!/usr/bin/env python3
import json
import sys
import os

def main():
    # Read Terraform output
    try:
        terraform_output = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        print("Error: Invalid JSON from Terraform output")
        sys.exit(1)

    # Get Windows VM IP
    windows_vm_ip = terraform_output.get("windows_vm_public_ip", {}).get("value")

    if not windows_vm_ip:
        print("Error: Windows VM IP not found in Terraform output")
        sys.exit(1)

    # Generate Ansible inventory
    inventory_dir = "../../../ansible/inventory"

    # Create inventory file
    with open(os.path.join(inventory_dir, "hosts"), "w") as f:
        f.write("[windows]\n")
        f.write(f"{windows_vm_ip}\n\n")
        f.write("[windows:vars]\n")
        f.write("ansible_user=opc\n")
        f.write("ansible_connection=winrm\n")
        f.write("ansible_winrm_server_cert_validation=ignore\n")
        f.write("ansible_winrm_transport=basic\n")
        f.write("ansible_winrm_port=5985\n")

    print(f"Ansible inventory generated at {os.path.join(inventory_dir, 'hosts')}")

if __name__ == "__main__":
    main()
