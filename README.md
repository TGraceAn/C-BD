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
- First
```bash
gcloud auth login --no-launch-browser
# (Copy the link to your browser, approve, and paste the code back here)
```
- Then
```bash
# Enable the computer server API so we can create VMs
gcloud services enable compute.googleapis.com
```
5. Create the Keys
```
ssh-keygen -t rsa -f ./keys/spark_key -C "ansible" -N ""
```
6. Terraform
- Open ```terraform/terraform.tfvars``` 
Fill in
```bash
project_id = ""
region     = ""
zone       = ""
ssh_user   = ""
```
For example
```bash
project_id = "YOUR PROJECT ID"
region     = "us-central1"
zone       = "us-central1-a"
ssh_user   = "ubuntu"
```
- Then run
```bash
cd terraform
terraform init
terraform apply -auto-approve
```
- After this you should but the correct IP for the ansible (inventory EXTERNAL_IP), site -> INTERNAL_IP for master (use ```gcloud compute instances list```)
7. Ansible
```bash
cd ../ansible
ansible-playbook -i inventory.ini site.yml
```
8. **IMPORTANT:** SAVE MONEY remember to destroy it after use
```bash
cd ../terraform
terraform destroy -auto-approve
```
9. To re-run after destroy...
- Run
```bash
cd terraform
terraform apply -auto-approve
```
- Update IPs in the ansible in ```ansible/inventory.ini```
- Then again
```bash
cd ../ansible
ansible-playbook -i inventory.ini site.yml
```

### Adding more nodes
1. Copy ```spark_worker_1``` in ```terraform/main.tf``` to make another one.
For example
```bash
# ADD THIS BLOCK
resource "google_compute_instance" "spark_worker_2" {
  name         = "spark-worker-2"
  machine_type = "e2-medium"
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.spark_subnet.id
    access_config {}
  }
  service_account {
    scopes = ["cloud-platform"]
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }
}

# UPDATE OUTPUTS
output "worker_2_ip" {
  value = google_compute_instance.spark_worker_2.network_interface.0.access_config.0.nat_ip
}
```
Remember to update ```ansible/inventory.ini``` with more workers

2. Apply the changes
```bash
cd terraform
terraform apply -auto-approve
```

3. In ```ansible/inventory.ini```, add the IP for the new worker.

4. Then run this
```bash
cd ../ansible
ansible-playbook -i inventory.ini site.yml
```
Ansible will auto skip the ones that already applied.

## Project setup
### Data prep
1. To setup the "HUGE DATA" let's put it in GCS (Since I don't want to set up 'back up' for HDFS)<br>
Set up this in docker (to set up one time GCS)
```bash
gsutil mb -l us-central1 gs://usth-cloud-bigdata-project
```
Of course you can change it to your region with your naming...<br>
Mine: ```gs://usth-bigdata-project-12345```

2. Create the filesample.txt from Hagimont's sample
```bash
mkdir data
cd data
nano filesample.txt
```
and paste the content.
3. Create (Add?) the same generate.sh to create a large dataset
```bash
nano generate.sh
```
Like Hagimont, create a 8GB file using 23 times duplicate... (maybe on GCP make it less... so 22? 21? 20?)
```bash
source generate.sh filesample.txt 20
```
4. I copy it to the GCS
```bash
gsutil cp data.txt gs://usth-bigdata-project-12345/data.txt
```

### Application setup
1. First, connect to the edge node (say you will run stuff from here)
```bash
ssh -i ../keys/spark_key ubuntu@<EDGE_IP>
```

2. Copy the WCStreaming java files for Spark Streaming from script to get your App (use nano for example)

3. Remember to do ```hostname -I``` to get the host IP

4. To JAR
```bash
javac -cp "/opt/spark/jars/*:." WordCountStreaming.java
```
Since I'm using spark 3.5 so it will have some warnings but it works fine (I think), change to spark 2.4 like the project if needed.<br>
Remember:
```bash
javac MyNC.java
java -cp . MyNC
```

5. Package into jar
```bash
jar cf streaming.jar WordCountStreaming*.class
```

6. Test
```bash
java -cp . MyNC
```
For streaming...
```bash
gsutil cat gs://usth-bigdata-project-12345/data.txt | nc -lk 9999
```
-> This will put the file in the pipe to start counting

7. Open another terminal and join the docker:
```bash
docker exec -it spark-shell bash
```
Then go to edge

8. Enter the Master IP and get the submit
```bash
/opt/spark/bin/spark-submit \
  --class WordCountStreaming \
  --master spark://<MASTER_INTERNAL_IP>:7077 \
  streaming.jar
```

9. Normal, No streaming<br>
I've created this first for clean printing
```bash
nano log4j.properties
```
```txt
log4j.rootCategory=ERROR, console

log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.target=System.err
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n

log4j.logger.WordCountStreaming=INFO
```

Run:
```bash
javac -cp "/opt/spark/jars/*:." WordCount.java
jar cf wc.jar WordCount.class
```
```bash
/opt/spark/bin/spark-submit \
  --class WordCount \
  --master spark://10.0.1.10:7077 \
  --conf spark.hadoop.fs.gs.impl=com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem \
  --conf spark.hadoop.fs.AbstractFileSystem.gs.impl=com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS \
  --conf spark.hadoop.google.cloud.auth.service.account.enable=true \
  --driver-java-options "-Dlog4j.configuration=file:/home/ubuntu/log4j.properties" \
  wc.jar gs://usth-bigdata-project-12345/data.txt output_gcs_result
```

Can always go this link to check:
```
http://<MASTER-EXTERNAL-IP>:8080
```

### Result

|    | 2 Nodes | 3 Nodes |4 Nodes |
| -------- | ------- | ------- |------- |
| Speed (ms)  | 50517    |43588 | 32510 |
