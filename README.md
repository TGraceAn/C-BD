# C-BD
initial commit for the project, I think

## Terraform and Ansible setup

### Steps
1. First run the Dockerfile
2. Then
```bash
docker build -t spark-deployer .
```
3. Get in using

```bash
docker run -it --rm \
  -v $(pwd):/project \
  -v ~/.config/gcloud:/root/.config/gcloud \
  --name spark-shell \
  spark-deployer
```
4. Authenticate with Google
```bash
# Log in to GCP
gcloud auth login --no-launch-browser
# (Copy the link to your browser, approve, and paste the code back here)

# Set your specific project ID (Found in your GCP Dashboard)
gcloud config set project YOUR_PROJECT_ID_HERE

# Enable the computer server API so we can create VMs
gcloud services enable compute.googleapis.com
```
5. Create the Keys
```
ssh-keygen -t rsa -f ./keys/spark_key -C "ansible" -N ""
```
6. Terraform
- Open ```terraform/main.tf``` and ensure the project field matches your GCP Project ID.
- Then run
```
cd terraform
terraform init
terraform apply -auto-approve
```
7. Ansible
```
cd ../ansible
ansible-playbook -i inventory.ini site.yml
```
**8. IMPORTANT:** SAVE MONEY by
```
cd terraform
terraform destroy -auto-approve
```
9. To re-run after destroy...
- Run
```
cd terraform
terraform apply -auto-approve
```
- Update IPs in the ansible in ```ansible/inventory.ini```
- Then again
```
cd ../ansible
ansible-playbook -i inventory.ini site.yml
```