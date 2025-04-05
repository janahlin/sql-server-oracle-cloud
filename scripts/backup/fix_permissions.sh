#!/bin/bash

# Make sure the deployment script is executable
chmod +x scripts/deploy.sh

# Recreate the terraform.tfvars.json file with the appropriate permissions
cd terraform/environments/dev/

cat > terraform.tfvars.json << 'EOF'
{
  "tenancy_ocid": "ocid1.tenancy.oc1..aaaaaaaawcczb6nidnd6rfoqmbvqg6dihslqsrrgnw6kysz6yix4lcvig2va",
  "user_ocid": "ocid1.user.oc1..aaaaaaaahkxj6jzddyrmwb5ursmz76sesxlcn7htop2nfv3fb66jjzehftza",
  "fingerprint": "09:fd:0f:58:f5:5e:7f:1c:98:d7:a6:19:76:48:4e:8c",
  "private_key_path": "~/.oci/oci_api_key.pem",
  "region": "eu-stockholm-1",
  "compartment_id": "ocid1.tenancy.oc1..aaaaaaaawcczb6nidnd6rfoqmbvqg6dihslqsrrgnw6kysz6yix4lcvig2va",
  "availability_domain": "GiQi:EU-STOCKHOLM-1-AD-1",
  "windows_image_id": "ocid1.image.oc1.eu-stockholm-1.aaaaaaaavvubpflzqzb3i3fgw2rj72jsomhxubi4g7mjgp5jdofokqrbkn5q",
  "ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDRMoKl++2aJbgZXvW8VtzvwU2zD1amEjwtQaoKU0Lb14Z3coV7KVbxq44VVqfIqGUeIOlFVI/zOjesC/Q4K8hVzboSGWBnLvMWX3Uq9h/NpSyhyfuHFQ1tzjGI1w3tN0m6hrYHVwWtydn5XT1JAWbtyGBmYMlA1wWV5ERDWtn4YjIN9jB9GI63YqN9/yn03yuZe87CY4szr3UMG8qh+BU1IrVHQh0vLNZtZbGk6p5P0JPBgyO+xMiliIupLGa7L5c19bSJP0jQfhc9SZAgPclqTxop9TbdDFNT+RCFVz3G8j1vHwvuVzMAseBBgxr6pE1J//wzEvfa0phRLvAJL+za6dxtKaqIgs2MKY+V6b3wwgXzb8TO9BMoSfEjxGdT2JnUkYt08KSqo9eXHrRr3lHc6mfVZ3iTPop9XuoPJFD3TWaRIhTgFltdMl/lqBsOcbrNmP9HsuAg+kuBYipSrag2IZzXfrFkfMA+BeBstZID1aCWSS3xk6bMpHMWGykuWxVxBKiqk05uWJy37IkYU6ddN5jjiTBKeeYv5157G7NwNv8pDDahRevlOUfVPnCijFZ/A7zBrL6pTV70HYsSgPya+qv1zuvH8NbH3rrNdazWnoPmyjLom8N+MJLQcHh1dpy3yrkO837T9Oig65FnwG25fLFJemNL9pjAal3VefKZ8w== terraform",
  "shape": "VM.Standard2.1"
}
EOF

# Set proper permissions
chmod 0600 terraform.tfvars.json

cd -

echo "Fixed permissions and recreated terraform.tfvars.json with correct shape"
echo "Try running the deployment again:"
echo "./scripts/deploy.sh" 