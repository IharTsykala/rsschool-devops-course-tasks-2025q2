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

---

# AWS DevOps Course – Task 2: Basic Infrastructure Configuration

## 🧩 Task Summary

This task focuses on building a production-ready network layout using Terraform. It includes the following components:

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

---

# AWS DevOps Course – Task 3: Kubernetes Cluster Setup (K3s)

## 📦 Goal

Deploy a lightweight Kubernetes cluster (K3s) inside the private subnet using EC2 instances and access it securely from your local machine through a Bastion host.

## 🛠️ What Terraform Automates

- EC2 instance for control plane (private subnet)
- EC2 instance(s) for worker nodes (private subnet)
- Bastion host in public subnet
- Proper security groups to allow SSH and Kubernetes traffic internally
- Routing and NAT for internet access from private subnet
- SSH key pair for instance access
- `user_data` scripts that install K3s automatically on startup:
  - On control plane: `curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644`
  - On workers: Join script using token from control plane

---

## 🔧 Manual Steps Required

Due to private networking constraints, some manual steps are needed to access and verify the cluster:

### 1. Connect to Bastion host

```bash
ssh -i cluster_key.pem ec2-user@<BASTION_PUBLIC_IP>
```

### 2. Copy SSH key to Bastion

```bash
scp -i cluster_key.pem cluster_key.pem ec2-user@<BASTION_PUBLIC_IP>:~
```

### 3. SSH into control plane from Bastion

```bash
ssh -i cluster_key.pem ec2-user@<CONTROL_PLANE_PRIVATE_IP>
```

### 4. Retrieve kubeconfig

```bash
sudo cat /etc/rancher/k3s/k3s.yaml
```

Copy the output to your local machine and edit the server address:

```yaml
server: https://127.0.0.1:6443
```

Save it as `~/k3s.yaml`

### 5. Port forwarding

From your **local machine**, run:

```bash
ssh -i cluster_key.pem -L 6443:<CONTROL_PLANE_PRIVATE_IP>:6443 ec2-user@<BASTION_PUBLIC_IP>
```

This forwards local port `6443` to the Kubernetes API server.

### 6. Test access

```bash
KUBECONFIG=~/k3s.yaml kubectl get nodes
```

You should see control plane and worker nodes in `Ready` state.

---

## ✅ Validation

- `kubectl get nodes` from local machine returns valid node list
- Cluster is deployed across private subnets
- Access is restricted to local via Bastion SSH forwarding
- Demonstrates real-world secure Kubernetes access pattern

# Task 4: Jenkins Installation & Configuration**

> **Variant:** local lab on **Minikube** (0 $ cloud cost)

---

## 🌟 Goal
Deploy Jenkins on a local Minikube cluster with persistent storage, configure it with Helm + JCasC, prove the configuration survives pod restarts and show a *Hello world* job.

---

## 📂 Project Structure

```
kubernetes/
└─ jenkins/
   ├─ Chart.yaml          # wrapper‑chart pulling the official Jenkins chart
   ├─ Chart.lock          # dependency lock
   ├─ values.yaml         # our overrides + JCasC snippet
terraform/                # left from previous tasks
kubernetes/pvc-test.yaml  # tiny PVC demo (PV/PVC requirement)
```

---

## 0. Prerequisites

```bash
brew install helm minikube kubernetes-cli   # macOS via Homebrew
minikube start                              # driver=docker (Docker Desktop must be running)
```

---

## 1. Helm Installation & Verification (10 pts)

```bash
helm version --short
minikube version
kubectl version --client
kubectl get nodes

# Smoke‑test NGINX
kubectl create ns helm-test
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install nginx-test bitnami/nginx -n helm-test
kubectl get pods,svc -n helm-test

kubectl port-forward svc/nginx-test 8080:80 -n helm-test
# open http://localhost:8080   -> “Welcome to nginx!”

helm uninstall nginx-test -n helm-test
kubectl delete ns helm-test
```

✅ Helm can deploy & remove charts.

---

## 2. Cluster Requirements – PV/PVC (10 pts)

Minikube ships with the `standard` hostPath StorageClass.

```bash
kubectl get storageclass

kubectl apply -f kubernetes/pvc-test.yaml
kubectl get pvc pvc-test
kubectl delete pvc pvc-test
```

Persistent storage working.

---

## 3. Jenkins Installation (40 pts)

### 3.1 Wrapper‑chart (`kubernetes/jenkins/Chart.yaml`)

```yaml
apiVersion: v2
name: my-jenkins
version: 0.1.0
dependencies:
  - name: jenkins
    version: 4.3.15
    repository: https://charts.jenkins.io
```

### 3.2 Custom `values.yaml` (excerpt)

```yaml
controller:
  persistence:
    enabled: true
    size: 8Gi
  JCasC:
    enabled: true
    configScripts:
      hello-job: |
        jobs:
          - script: >
              job('hello-world-job') {
                steps {
                  shell('echo "Hello world"')
                }
              }
```

### 3.3 Deploy

```bash
helm dependency update kubernetes/jenkins
helm upgrade --install my-jenkins kubernetes/jenkins   --namespace jenkins --create-namespace
kubectl get pods -n jenkins        # jenkins-0 -> Running
```

### 3.4 Access Jenkins

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
kubectl exec -n jenkins -it svc/jenkins -c jenkins   -- cat /run/secrets/additional/chart-admin-password
# login → http://localhost:8080  (user: admin)
```

---

## 4. Jenkins Configuration Persistency (10 pts)

1. Edit *System Message* (“Jenkins setup by …”).
2. Delete controller pod:

   ```bash
   kubectl delete pod -l app.kubernetes.io/component=jenkins-controller -n jenkins
   ```
3. New pod starts ⇒ message **persists** (stored on the PV).

---

## 5. Verification – *Hello world* Job (15 pts)

* `hello-world-job` appears automatically (JCasC).
* Run job → **Console Output**

  ```
  + echo "Hello world"
  Hello world
  Finished: SUCCESS
  ```

---

## 6. Additional Tasks (💫 15 pts)

- **GitHub Actions pipeline** – *not required for the Minikube scenario; course video states these 5 pts are granted automatically*
- **Authentication & Security** – built-in Jenkins user database, self-sign-up and anonymous access disabled, inbound agent port fixed to **50000**
- **JCasC job definition** – the `hello-job` pipeline is declared in `kubernetes/jenkins/values.yaml` 

---

## 7. Full Cluster Snapshot

```bash
kubectl get all --all-namespaces
```

*(screenshot attached in PR)*

---

## 8. Re‑deployment Quick Guide

```bash
minikube start
helm dependency update kubernetes/jenkins
helm upgrade --install my-jenkins kubernetes/jenkins   --namespace jenkins --create-namespace
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

🎉 Jenkins up & running locally with persistent config and auto‑provisioned *Hello world* job!

# Task 5: Helm Chart Deployment on Minikube

## 📦 Project Structure

```
.
├── app/                         # Node.js application
│   ├── index.js
│   ├── Dockerfile              # Dockerfile for the app
│   ├── package.json
│   └── ...
├── kubernetes/
│   ├── jenkins/                # From previous task
│   └── node-app/               # Helm chart for the app
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── pvc-test.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── ingress.yaml
├── terraform/                  # From previous tasks
```

---

## 🔹 Steps Performed

### 1. Created a Node.js Application

A simple Express server (`index.js`) that returns “Hello, World from Node.js!”.

### 2. Built and Pushed Docker Image to Docker Hub

```bash
cd app
docker build -t ihartsykala/node-hello:1.0 .
docker push ihartsykala/node-hello:1.0
```

> Make sure Docker is running and you're logged in (`docker login`).

---

### 3. Created Helm Chart for the App

```bash
cd kubernetes
helm create node-app
```

Modified `values.yaml` to use Docker image:

```yaml
image:
  repository: ihartsykala/node-hello
  tag: "1.0"
```

---

### 4. Started Local Minikube Cluster

```bash
minikube start
minikube status
```

> You can verify `kubectl` is configured correctly by running:

```bash
kubectl get nodes
```

---

### 5. Deployed Helm Chart to Minikube

```bash
cd kubernetes/node-app
helm upgrade --install node-app . \
  -n node-app --create-namespace
```

---

### 6. Verified Application is Running

Expose the service via Minikube:

```bash
minikube service node-app -n node-app --url
```

You should see output like:

```
http://127.0.0.1:62648
```

Visit this URL in your browser — it should show:

```
Hello, World from Node.js!
```

---

## ✅ What This Solves

- Helm chart is created and used to deploy a Dockerized Node.js app
- Application is verified to be working in a local Kubernetes cluster
- Fully satisfies Task 5 requirements (Helm, Docker, K8s, Minikube)


# Task 6 – Application Deployment via Jenkins Pipeline (Local **Minikube** lab)

This guide combines the **lab bootstrap** (Jenkins + SonarQube on Minikube) with the **production‑ready Jenkinsfile** that builds, verifies and deploys the sample Node.js application, pushes an image to Docker Hub and sends **Telegram** notifications on every run.

> Tested on **macOS 14 + Docker Desktop 4.29 + Minikube v1.36**  
> (Linux/Windows commands are identical except for the package manager)

---

## 0. Repository Layout

```
.
├── app/                        # Node.js application
│   ├── index.js
│   ├── __tests__/index.test.js
│   ├── Dockerfile              # Runtime image (slim)
│   └── docker/Dockerfile.ci    # CI image with dev dependencies
├── kubernetes/
│   ├── jenkins/                # Wrapper‑chart for Jenkins (Task 4)
│   └── node-app/               # Helm chart used by the pipeline
├── terraform/                  # AWS IaC (Tasks 1‑3)
├── Jenkinsfile                 # 💡 Pipeline described below
└── README.md                   # Task docs
```

*`Dockerfile.ci`* was added specifically for the **Build / Unit‑test / Sonar** stages to keep the runtime image small.

---

## 1. Prerequisites

```bash
brew install docker minikube kubernetes-cli helm   # macOS
open -a "Docker"                                   # start Docker Desktop
docker --version && minikube version
kubectl version --client && helm version --short
```

---

## 2. Start a Clean Minikube Cluster

```bash
minikube start --memory 6000 --cpus 4
minikube status
kubectl get nodes   # should be Ready
```

---

## 3. Spin‑up **Jenkins** + **SonarQube**

### 3.1 Jenkins (Helm)

```bash
kubectl create namespace jenkins

helm repo add jenkins https://charts.jenkins.io
helm repo update

helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins \
  --set controller.adminUser=admin \
  --set controller.adminPassword=admin \
  --set controller.resources.requests.cpu="500m" \
  --set controller.resources.requests.memory="1.5Gi" \
  --set controller.resources.limits.memory="2Gi" \
  --set persistence.enabled=true \
  --set persistence.size=8Gi

kubectl get pods -n jenkins                     # jenkins-0 2/2 Running
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

Log in to **<http://localhost:8080>** with the credentials above (or fetch the auto‑generated password):

```bash
kubectl exec -it svc/jenkins -c jenkins -n jenkins \
  -- cat /run/secrets/additional/chart-admin-password
```

Finish the first‑run wizard → **Suggested plugins**.

---

### 3.2 SonarQube (YAML manifest)

```bash
kubectl apply -f kubernetes/sonarqube.yaml -n jenkins
kubectl get pods -n jenkins            # sonarqube-xxxxx 1/1 Running
minikube service sonarqube -n jenkins --url   # http://127.0.0.1:15108
```

Log in (admin / admin) and generate a **user token**  
**My Account → Security → Generate Token** → copy & save.

---

## 4. Jenkins Global Configuration

| Section | What to add |
|---------|-------------|
| **Manage Jenkins → Credentials** | • `github-token` – GitHub PAT (Secret Text)<br>• `dockerhub-creds` – Docker Hub user/pass (Username/Password)<br>• `sonarqube-token` – SonarQube token (Secret Text)<br>• `TELEGRAM_TOKEN` & `TELEGRAM_CHAT_ID` – credentials described in §5 |
| **Configure System → SonarQube servers** | Name **sonarqube**, URL `http://sonarqube.jenkins.svc.cluster.local:9000`, Credentials **sonarqube-token** |
| **Configure Global Security** | Disable anonymous read, fix inbound agent port 50000 (already chart default) |

---

## 5. Telegram Notification Channel

1. **Create a bot**

   ```
   @BotFather →  /newbot
   Bot name: Jenkins Notifier
   Username: jenkinsciXXXXbot (must end with *bot*)
   ```
   Copy the **API token** – `8061677707:AA...`.

2. **Get chat‑id**

   ```
   curl -s https://api.telegram.org/bot<API_TOKEN>/getUpdates
   ```
   After you send any message to the bot (e.g. `/start`), your chat id is in the JSON (`"chat":{"id":391880672,...}`).

3. **Store in Jenkins**

   *Credentials → (Kind: Secret text)*
  - ID `TELEGRAM_TOKEN`  → *the bot token*
  - ID `TELEGRAM_CHAT_ID` → *the numeric chat id*

The Jenkinsfile (see next chapter) uses these IDs to `curl` the Bot API in **post** actions.

---

## 6. The Jenkinsfile (high‑level)

```groovy
stages {
  Build          // npm ci inside docker/dockerfile.ci
  Test           // jest
  SonarQube      // sonar-scanner, waits for quality gate
  Docker Build   // eval $(minikube docker-env) ; docker build
  Docker Push    // docker login && docker push
  Helm Deploy    // helm upgrade --install node-app  …
  Verify         // curl http://node-hello-node-app.jenkins.svc.cluster.local
}
post {
  success { notifyTG("✅ Jenkins pipeline succeeded …") }
  failure { notifyTG("❌ Jenkins pipeline failed …")   }
}
```

Key implementation details:

| Piece | How it’s done |
|-------|---------------|
| **Build image** | Local Minikube Docker daemon → **instant** push‑less deploy /
| **Manual ECR build** | Wrapped in `when { triggeredBy 'UserIdCause' }` so it never slows normal pushes |
| **Verification** | `curl -s -o /dev/null -w "%{http_code}"` against the *ClusterIP* service; logs + pod list printed on failure |
| **Notification** | `withCredentials([string(...)] ) { curl -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" -d chat_id=$TG_CHAT -d text="$MSG" }` |

---

## 7. Running the Pipeline

1. **Create job** (`Pipeline script from SCM`, branch pattern `feat/task-6-*` or `*/*`, credentials `github-token`).
2. Push any commit → Jenkins detects change → full build.
3. **Manual promotion** – click **Build with Parameters** and select *Build & Push to ECR* when you need a prod image.

Successful run output:

```text
…
Verify Application ....................... ✔ 200 OK
Finished: SUCCESS
Sent notification → Telegram ✅
```

![telegram_screenshot](../../visual_assets/telegram_ok.png)

---

## 8. Clean‑up (optional)

```bash
helm uninstall jenkins -n jenkins
kubectl delete -f kubernetes/sonarqube.yaml -n jenkins
minikube delete
```

---

## 9. What This Delivers

| Criterion | ✔ Implementation |
|-----------|------------------|
| **Pipeline steps** | build, unit‑test, Sonar, Docker build/push, Helm deploy, smoke test |
| **Artifacts** | `Dockerfile`, `Dockerfile.ci`, Helm chart, Docker Hub image |
| **Verification** | Automated curl + HTTP 200 check |
| **Notification** | Telegram bot messages for **SUCCESS / FAILURE** |
| **Documentation** | This README 📝 |

# Task 7 – Prometheus Deployment on K8s (Local **Minikube** lab)
