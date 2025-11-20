# Use Ubuntu as the base image
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    openssh-client \
    python3 \
    python3-pip \
    software-properties-common \
    gnupg \
    vim

# 2. Install Terraform (Corrected for Apple Silicon)
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform

# 3. Install Ansible
RUN apt-add-repository --yes --update ppa:ansible/ansible && \
    apt-get install -y ansible

# 4. Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update && apt-get install -y google-cloud-cli

# 5. Set the working directory
WORKDIR /project

# Keep container running
CMD ["bash"]