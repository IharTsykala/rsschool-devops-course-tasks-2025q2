# AWS DevOps Course – Task 1: Terraform Infrastructure

## 🚀 Project Structure

- `terraform/backend-setup`: Directory for creating the S3 bucket for the backend
- `terraform/`: Main infrastructure (IAM, bucket, GitHub OIDC)
- `.github/workflows/deploy.yml`: GitHub Actions CI/CD pipeline

---

## 🔹 Manual Execution

### Step 1. Create the backend S3 bucket

```bash
cd terraform/backend-setup
terraform init
terraform apply -auto-approve
```

This step creates the `terraform-states-ihar-tsykala-2025q2` bucket used as the remote backend.

---

### Step 2. Initialize the main Terraform code

```bash
cd ..
terraform init
terraform plan
```

---

### Step 3. Import existing IAM Role (if it already exists)

```bash
terraform import aws_iam_role.GithubActionsRole GithubActionsRole
```

---

### Step 4. Apply full infrastructure

```bash
terraform apply -auto-approve
```

---

## 🔹 GitHub Actions

CI/CD pipeline runs 3 jobs:

- `terraform-check` — formatting validation
- `terraform-plan` — plan preview
- `terraform-apply` — deploys on push to `main`

Before running `terraform init`, there is a step to ensure the backend bucket exists:

```bash
aws s3api head-bucket --bucket terraform-states-ihar-tsykala-2025q2 || \
aws s3api create-bucket --bucket terraform-states-ihar-tsykala-2025q2 --region us-east-1
```

---

## ✅ What This Solves

- Prevents `NoSuchBucket` errors on backend init
- Backend bucket is managed through Terraform in a separate step
- Fully satisfies the course requirements by using infrastructure-as-code


# AWS DevOps Course – Task 2: Basic Infrastructure Configuration

## 🧩 Task Summary

This task focuses on building a production-ready network layout using Terraform.
It includes the following components:

- Custom VPC
- Public and private subnets
- Internet Gateway (IGW)
- NAT instance
- Bastion host
- Route Tables
- Security Groups and NACLs
- EC2 instances for testing
- GitHub Actions integration

---

## 🌐 VPC and Subnets

- **VPC CIDR**: `10.0.0.0/16`
- **Public Subnets**:
    - `10.0.1.0/24` (`us-east-1a`)
    - `10.0.2.0/24` (`us-east-1b`)
- **Private Subnets**:
    - `10.0.3.0/24` (`us-east-1a`)
    - `10.0.4.0/24` (`us-east-1b`)

Each subnet is tagged appropriately and linked to corresponding route tables and NACLs.

---

## 🌐 Internet Gateway and Route Tables

- An Internet Gateway (IGW) is attached to the VPC.
- Public route table:
    - Routes `0.0.0.0/0` to the IGW.
- Private route table:
    - Routes `0.0.0.0/0` to the NAT instance's network interface.

---

## 🔐 Security Groups

- `security_group_public_from_bastion`: Allows SSH access from the internet.
- `security_group_public_from_nat`: Allows all TCP traffic from Bastion/NAT.
- `security_group_private_to_bastion`: Allows SSH traffic from Bastion subnet.
- `security_group_private_to_nat`: Allows full traffic from NAT subnet.

---

## 📜 Network ACLs

- Public NACL:
    - Inbound: Allows HTTP(80), SSH(22) from `0.0.0.0/0`
    - Outbound: Allows all
- Private NACL:
    - Inbound:
        - SSH(22) from Bastion
        - All return traffic (for TCP handshakes)
    - Outbound: All

---

## 🧱 Bastion Host

- EC2 instance in public subnet with public IP
- Security group allows SSH access from the internet
- Used for connecting securely to private EC2 instances

---

## 🛰️ NAT Instance

- EC2 NAT instance in the public subnet
- Has EIP and routing rules for outbound traffic from private subnets
- `iptables` rules added via `user_data` to enable forwarding

---

## 🧪 Test EC2 Instances

- One in public subnet (to test public access)
- One in private subnet (to verify NAT access)
- One in private subnet (to test Bastion access)

---

## ⚙️ GitHub Actions Pipeline

- Located in `.github/workflows/deploy.yml`
- Steps:
    1. Check formatting
    2. Run `terraform plan`
    3. Ensure backend bucket exists
    4. Apply Terraform

---

## ✅ Validation

- All EC2 instances are reachable as expected:
    - Public instance: reachable from the internet
    - Private to NAT: has outbound internet via NAT
    - Private to Bastion: reachable via Bastion
- NAT and Bastion are deployed with correct routing and security settings
- All resources tagged and follow best practices
