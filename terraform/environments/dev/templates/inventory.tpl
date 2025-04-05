[windows]
sqlserver ansible_host=${vm_ip}

[windows:vars]
ansible_user=${admin_user}
ansible_password=${admin_pass}
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
ansible_winrm_transport=basic
ansible_port=5985
# ssh_public_key=${ssh_key}
