#!/bin/bash

# Check arguments
if [ -z "$1" ]; then
  echo "Usage: ./run_terraform.sh <number_of_workers>"
  exit 1
fi

WORKER_COUNT=$1

echo "------------------------------------------------"
echo "  Deploying Spark Cluster with $WORKER_COUNT Workers..."
echo "------------------------------------------------"

cd terraform

# 1. Run Terraform
terraform apply -var="worker_count=$WORKER_COUNT" -auto-approve

# 2. Capture Outputs
echo "------------------------------------------------"
echo "  Generating Ansible Inventory..."
echo "------------------------------------------------"

# Get raw IPs
MASTER_IP=$(terraform output -raw master_ip)
EDGE_IP=$(terraform output -raw edge_ip)

# Parse Worker IPs: Remove brackets/quotes and swap commas for newlines
WORKER_IPS=$(terraform output -json worker_ips | tr -d '[]"' | tr ',' '\n')

# Define Ansible connection params
ANSI_PARAMS="ansible_user=ubuntu ansible_ssh_private_key_file=../keys/spark_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'"
INVENTORY_FILE="../ansible/inventory.ini"

# 3. Write to inventory.ini

# Write Master
echo "[master]" > $INVENTORY_FILE
echo "$MASTER_IP $ANSI_PARAMS" >> $INVENTORY_FILE
echo "" >> $INVENTORY_FILE

# Write Workers
echo "[workers]" >> $INVENTORY_FILE
for ip in $WORKER_IPS; do
    # [FIX] Use single brackets [ ] instead of [[ ]] for compatibility
    if [ -n "$ip" ]; then
        # Use xargs to trim whitespace
        CLEAN_IP=$(echo "$ip" | xargs)
        echo "$CLEAN_IP $ANSI_PARAMS" >> $INVENTORY_FILE
    fi
done
echo "" >> $INVENTORY_FILE

# Write Edge
echo "[edge]" >> $INVENTORY_FILE
echo "$EDGE_IP $ANSI_PARAMS" >> $INVENTORY_FILE
echo "" >> $INVENTORY_FILE

# Write Groups
echo "[spark_cluster:children]" >> $INVENTORY_FILE
echo "master" >> $INVENTORY_FILE
echo "workers" >> $INVENTORY_FILE
echo "edge" >> $INVENTORY_FILE

cd ..

echo "  Success! Inventory generated:"
cat ansible/inventory.ini