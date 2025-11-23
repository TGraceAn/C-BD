#!/bin/bash

echo "------------------------------------------------"
echo "  Preparing to Configure Spark Cluster..."
echo "------------------------------------------------"

# 1. Auto-detect the Master's INTERNAL IP (Private VPC IP)
# We need this because Workers must talk to Master via Internal IP, not Public.
echo "Querying GCP for Spark Master Internal IP..."
MASTER_INTERNAL_IP=$(gcloud compute instances list --filter="name=spark-master" --format="get(networkInterfaces[0].networkIP)")

if [ -z "$MASTER_INTERNAL_IP" ]; then
  echo "❌ Error: Could not find 'spark-master' running on GCP."
  echo "   Did you run ./run_terraform.sh first?"
  exit 1
fi

echo "  Detected Master Internal IP: $MASTER_INTERNAL_IP"

# 2. Check if Inventory exists
if [ ! -f "ansible/inventory.ini" ]; then
  echo "❌ Error: ansible/inventory.ini not found."
  echo "   Please run ./run_terraform.sh to generate it."
  exit 1
fi

# 3. Run Ansible
echo "------------------------------------------------"
echo "  Running Ansible Playbook..."
echo "------------------------------------------------"

cd ansible

# We pass 'spark_master_ip' as an extra variable to override defaults
ansible-playbook -i inventory.ini site.yml \
  --extra-vars "spark_master_ip=$MASTER_INTERNAL_IP"

# 4. Print Dashboard URL
# Extract Master Public IP from inventory for the user
MASTER_PUBLIC_IP=$(grep -A 1 "\[master\]" inventory.ini | tail -n 1 | awk '{print $1}')

echo "------------------------------------------------"
echo "  Configuration Complete!"
echo "  Spark Master UI: http://$MASTER_PUBLIC_IP:8080"
echo "------------------------------------------------"