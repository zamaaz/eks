# Terraform AWS EKS Cluster

This Terraform project provisions a secure, production-ready Amazon EKS (Elastic Kubernetes Service) cluster. It creates a managed control plane and a group of EC2 worker nodes, all configured to run securely within your custom VPC.

This module is the foundation for deploying containerized applications using Kubernetes on AWS, with a strong focus on security, observability, and operational stability.

## Features & Resources Created

- **EKS Cluster (`aws_eks_cluster`)**: A managed Kubernetes control plane with enhanced security.
- **Robust Security**:
  - **KMS Encryption**: Encrypts Kubernetes secrets at rest for an added layer of security.
  - **Restricted API Access**: The public API endpoint is restricted to a list of allowed IP addresses.
- **EKS Node Group (`aws_eks_node_group`)**: A group of EC2 instances that serve as the worker nodes for the cluster, deployed into private subnets.
- **Operational Stability**:
  - **Managed Add-ons**: Explicitly manages versions for `vpc-cni`, `coredns`, and `kube-proxy` for stable cluster operations.
  - **Graceful Updates**: Node groups are configured for rolling updates to minimize application downtime.
- **Observability**: All EKS control plane logs (`api`, `audit`, `authenticator`, etc.) are enabled and streamed to AWS CloudWatch.
- **Persistent Storage**: Includes the `aws-ebs-csi-driver` add-on to allow Kubernetes to provision and manage persistent storage using Amazon EBS volumes.
- **Dedicated IAM Roles & Policies**: Separate, least-privilege IAM roles for the EKS control plane and the worker nodes.

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

1.  **VPC with Public and Private Subnets**: You must have a VPC with both public and private subnets across at least two Availability Zones. Private subnets must have a route to a NAT Gateway for outbound internet access.
2.  **Terraform and AWS CLI**: Configured and ready to use.
3.  **kubectl**: The [Kubernetes command-line tool](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) must be installed.
4.  **Helm**: The [Helm package manager for Kubernetes](https://helm.sh/docs/intro/install/) must be installed.
5.  **Backend Infrastructure**: The resources from the `00-backend` project must be created first.

---

## State Management

This project uses a remote backend in AWS S3 and workspaces to manage different environments. Ensure the `backend.tf` file is present and configured correctly before initializing.

---

## How to Use (Cluster Provisioning)

1.  **Create an Environment Variables File**: This module requires network and access information. Create a file named `dev.tfvars` (or `prod.tfvars` for production).
    ```hcl
    # dev.tfvars
    vpc_id             = "vpc-xxxxxxxxxxxxxxxxx"
    public_subnet_ids  = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
    private_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
    api_allowed_cidrs  = ["YOUR.PUBLIC.IP/32"] # IMPORTANT: Change this to your IP
    ```
2.  **Initialize Terraform**: Initialize the project and create a workspace.
    ```bash
    terraform init
    terraform workspace new dev
    ```
3.  **Plan and Apply the Configuration**: Review the execution plan and, if it looks correct, apply the configuration.
    ```bash
    terraform plan -var-file="dev.tfvars"
    terraform apply -var-file="dev.tfvars"
    ```
    _Note: Creating an EKS cluster can take 10-15 minutes._

---

## Post-Provisioning: Deploying Applications

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
3.  **Install the Chart**: Install the chart, setting a secure password for the Grafana admin user from the command line.
    ```bash
    helm install my-custom-monitoring . --namespace monitoring --create-namespace --set grafana.adminPassword='your-secure-password'
    ```
4.  **Access Grafana**: Once the pods are running, run `kubectl --namespace monitoring port-forward svc/my-custom-monitoring-grafana 3000:80`. You can then access the dashboard at **http://localhost:3000** (user: `admin`, pass: the password you set during installation).

### Step 3: Deploy Keycloak

The `k8s-manifests/keycloak/` directory contains all the necessary YAML files to deploy a stateful Keycloak instance with a persistent PostgreSQL backend.

1.  **Apply the Manifests**: Run `kubectl apply -f k8s-manifests/keycloak/` from the root of the project directory.
2.  **Access Keycloak**: Get the public URL by running `kubectl get service keycloak-service`.

> #### Note on Production Readiness
>
> The included Keycloak deployment uses the `start-dev` command, which is suitable for development and testing. For a production environment, you must:
>
> - Change the container command to `start`.
> - Strongly consider using a managed database service like **Amazon RDS** instead of the self-hosted PostgreSQL deployment for high availability and data durability.

## Outputs

- `eks_cluster_endpoint`: The endpoint for your Kubernetes API server.
- `eks_cluster_name`: The name of the EKS cluster.
- `eks_cluster_arn`: The ARN of the EKS cluster.

## Cleaning Up

When you are finished, you must destroy the application and infrastructure resources in the correct order.

1.  **Uninstall Helm Charts**: `helm uninstall my-custom-monitoring --namespace monitoring`
2.  **Delete Kubernetes Resources**: `kubectl delete -f k8s-manifests/keycloak/`
3.  **Destroy Infrastructure**: Run `terraform destroy`. Terraform will automatically handle the correct dependency order for all cloud resources.
    ```bash
    terraform destroy -var-file="dev.tfvars"
    ```
