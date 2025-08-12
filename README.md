# Terraform AWS EKS Cluster

This Terraform project provisions a production-ready Amazon EKS (Elastic Kubernetes Service) cluster. It creates a managed control plane and a group of EC2 worker nodes, all configured to run securely within your custom VPC. It also includes the necessary EBS CSI driver for persistent storage.

This module is the foundation for deploying containerized applications using Kubernetes on AWS.

## Features & Resources Created

- **EKS Cluster (`aws_eks_cluster`)**: The managed Kubernetes control plane.
- **EKS Node Group (`aws_eks_node_group`)**: A group of EC2 instances that serve as the worker nodes for the cluster.
- **IAM Roles & Policies**: Dedicated IAM roles for the EKS control plane and the worker nodes.
- **EBS CSI Driver Add-on**: An essential add-on that allows Kubernetes to provision and manage persistent storage using Amazon EBS volumes.

## File Structure

```
.
├── main.tf
├── variables.tf
├── output.tf
└── charts/
    └── my-monitoring-stack/
└── k8s-manifests/
    └── keycloak/
```

## Prerequisites

1.  **VPC with Public and Private Subnets**: You must have a VPC with both public and private subnets across at least two Availability Zones. The `01-vpc` module creates this.
2.  **Terraform and AWS CLI**: Configured and ready to use.
3.  **kubectl**: The [Kubernetes command-line tool](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) must be installed.
4.  **Helm**: The [Helm package manager for Kubernetes](https://helm.sh/docs/intro/install/) must be installed.
5.  **Backend Infrastructure**: The resources from the `00-backend` project must be created first.

---

## State Management

This project uses a remote backend in AWS S3. Ensure the `backend.tf` file is present and configured correctly before initializing.

---

## How to Use (Cluster Provisioning)

1.  **Create `terraform.tfvars`**: This module requires network information. Create a file named `terraform.tfvars` in this directory with the outputs from your VPC module:
    ```hcl
    # terraform.tfvars
    key_name           = "your-key-name"
    vpc_id             = "vpc-xxxxxxxxxxxxxxxxx"
    public_subnet_ids  = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
    private_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
    ```
2.  **Initialize Terraform**: `terraform init`
3.  **Apply the Configuration**: `terraform apply`
    _Note: Creating an EKS cluster can take 10-15 minutes._

---

## Post-Provisioning: Deploying Add-ons

After your cluster is running, you can deploy applications onto it.

### Step 1: Configure kubectl

First, configure your local `kubectl` to connect to your new cluster.

```bash
aws eks update-kubeconfig --name <your-cluster-name> --region <your-region>
```

### Step 2: Deploy Prometheus & Grafana Monitoring

The `charts/my-monitoring-stack` directory contains a custom "umbrella" chart that deploys and configures Prometheus and Grafana.

1.  **Navigate to the chart directory**: `cd charts/my-monitoring-stack`
2.  **Update Dependencies**: `helm dependency update`
3.  **Install the Chart**:
    ```bash
    helm install my-custom-monitoring . --namespace monitoring --create-namespace
    ```
4.  **Access Grafana**: Once the pods are running, open a new terminal and run `kubectl --namespace monitoring port-forward svc/my-custom-monitoring-grafana 3000:80`. You can then access the dashboard at **[http://localhost:3000](https://www.google.com/search?q=http://localhost:3000)** (user: `admin`, pass: `admin`).

### Step 3: Deploy Keycloak

The `k8s-manifests/keycloak/` directory contains all the necessary YAML files to deploy a stateful Keycloak instance with a persistent PostgreSQL backend.

1.  **Apply the Manifests**: Run `kubectl apply -f k8s-manifests/keycloak/` from the root of the EKS module directory.
2.  **Access Keycloak**: Get the public URL by running `kubectl get service keycloak-service`.

## Outputs

- `eks_cluster_endpoint`: The endpoint for your Kubernetes API server.
- `eks_cluster_name`: The name of the EKS cluster.
- `eks_cluster_arn`: The ARN of the EKS cluster.

## Cleaning Up

When you are finished, you must destroy the resources in the correct order to avoid dependency errors.

1.  **Uninstall Helm Charts**: `helm uninstall my-custom-monitoring --namespace monitoring`
2.  **Delete Kubernetes Resources**: `kubectl delete -f k8s-manifests/keycloak/`
3.  **Destroy EKS Add-on**: Run the following command to destroy the EBS CSI driver first:
    ```bash
    terraform destroy -target=aws_eks_addon.ebs_csi
    ```
4.  **Destroy the Cluster**: Once the add-on is removed, destroy the rest of the cluster:
    ```bash
    terraform destroy
    ```
