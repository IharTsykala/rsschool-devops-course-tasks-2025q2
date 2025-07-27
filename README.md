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


# Task 7 – Prometheus & Grafana Monitoring via Jenkins Pipeline on **Minikube**

> **Variant:** Local lab using **Minikube** (Docker driver).  
> **Goal:** End‑to‑end CI/CD that deploys a monitoring stack (**Prometheus**, **Grafana**, exporters) and provisions **alerting** and **SMTP** **purely as code**. No GitHub Actions deployments are used here — **everything runs from Jenkins** (manually or via **Poll SCM/cron**).

---

## 0. Repository Structure (what comes from earlier tasks)

```
.
├── .github/                     # (from Task 1) Terraform CI linting only – not used for deployment in Task 7
├── app/                         # (from Task 5/6) Node.js demo application (+ tests)
│   ├── Dockerfile               # Runtime image
│   ├── docker/
│   │   └── Dockerfile.ci        # CI image (build + unit tests + sonar)
│   └── ...                      # Source and __tests__
├── kubernetes/
│   ├── jenkins/                 # (from Task 4) Wrapper-chart & values for local Jenkins on Minikube
│   └── node-app/                # (from Task 5/6) Helm chart used by the app pipeline
├── monitoring/                  # (Task 7) **Everything for Prometheus, Grafana, RBAC, SMTP and CI**
│   ├── Jenkinsfile              # Final pipeline that deploys & provisions monitoring
│   ├── grafana/
│   │   ├── values.yaml          # Helm overrides (custom image, initContainer, NodePort, persistence, datasource, SMTP)
│   │   ├── grafana-secret.yaml  # Admin creds (user/pass) as K8s Secret (mounted via values)
│   │   ├── dashboards/
│   │   │   └── node-metrics.json    # Example dashboard exported to JSON
│   │   └── docker/                  # Source for the “all‑provisioned” Grafana image
│   │       ├── Dockerfile           # Builds ihartsykala/grafana-alerting:latest
│   │       └── provisioning/
│   │           ├── alerting/
│   │           │   ├── contact-points.yaml
│   │           │   ├── notification-policies.yaml
│   │           │   └── rule-groups.yaml
│   │           ├── datasources/
│   │           │   └── datasources.yaml
│   │           ├── rules/           # reserved (not used in this lab)
│   │           └── grafana.ini
│   ├── prometheus/
│   │   └── values.yaml          # Helm overrides for bitnami/kube-prometheus
│   ├── rbac/
│   │   ├── jenkins-monitoring-access.yaml  # ServiceAccount + Role/RoleBinding within the namespace
│   │   └── jenkins-cluster-rbac.yaml       # ClusterRoleBinding (cluster-admin) for simplicity in the lab
│   └── smtp4dev/
│       └── smtp4dev.yaml        # Local SMTP server (mail‑catcher) for email alerts
└── terraform/                   # (from Tasks 1–3) AWS IaC – not used in this local Minikube lab
```

> **Important:** All **Task 7** files live under `monitoring/`. Jenkins for this lab was already bootstrapped in **Task 4** (Minikube + Helm). Application artifacts from **Task 5/6** stay in the repo but are unrelated to this deployment flow.

---

## 1. Prerequisites & Local Setup

- **Docker Desktop** (running)
- **Minikube** (Docker driver)
- CLIs: `kubectl`, `helm`, `docker`, `git`
- Branch: `feat/task-7-prometheus-deployment-on-k8s`

Quick checks:

```bash
docker --version
minikube version
kubectl version --client --short
helm version --short
```

Start a clean Minikube and verify node state:

```bash
minikube start --cpus=4 --memory=6000 --driver=docker
kubectl get nodes
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   ...   v1.33.x
```

> Minikube auto‑enables `storage-provisioner` and `default-storageclass` add‑ons. Ingress is **not** required for this task; access is via `port-forward` or a NodePort for Grafana.

---

## 2. Jenkins on Minikube (Helm)

Add the repo, create namespace and install Jenkins:

```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
kubectl create namespace jenkins || true

helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.requests.cpu=500m \
  --set persistence.enabled=true \
  --set persistence.size=8Gi
```

Wait for the controller:

```bash
kubectl get pods -n jenkins
# jenkins-0   2/2   Running
```

Open the UI via port‑forward:

```bash
kubectl -n jenkins port-forward svc/jenkins 8080:8080
# http://localhost:8080
```

Admin password (auto‑generated by the chart, if not overridden):

```bash
kubectl exec -n jenkins -it svc/jenkins -c jenkins -- \
  cat /run/secrets/additional/chart-admin-password
```

---

## 3. Jenkins Job Configuration

Create a Pipeline job **task-7-monitoring**:

- **Definition:** *Pipeline script from SCM*
- **Repository URL:** `https://github.com/IharTsykala/rsschool-devops-course-tasks-2025q2.git`
- **Branches to build:** `*/feat/task-7-prometheus-deployment-on-k8s`
- **Script Path:** `monitoring/Jenkinsfile`
- **Triggers:** `Poll SCM: H/2 * * * *` (check every ~2 minutes)

> In this lab **all deployments are triggered by Jenkins** (manual run or Poll SCM). GitHub Actions do not deploy the monitoring stack.

---

## 4. Final Jenkinsfile (used in this task)

```groovy
pipeline {
  agent {
    kubernetes {
      label 'monitoring'
      defaultContainer 'tools'
      yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
    - name: tools
      image: dtzar/helm-kubectl:3.14.4
      command: ["sh", "-c", "sleep 36000"]
      tty: true
"""
    }
  }

  triggers { pollSCM('H/2 * * * *') }

  options {
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  environment {
    NAMESPACE = 'monitoring'
    PROM_REL  = 'kube-prometheus'
  }

  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Helm repos') {
      steps {
        container('tools') {
          sh """
            helm repo add bitnami https://charts.bitnami.com/bitnami
            helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
            helm repo update
          """
        }
      }
    }

    stage('Ensure namespace') {
      steps {
        container('tools') {
          sh "kubectl get ns ${NAMESPACE} || kubectl create ns ${NAMESPACE}"
        }
      }
    }

    stage('RBAC Setup (namespace)') {
      steps {
        container('tools') {
          sh 'kubectl apply -f monitoring/rbac/jenkins-monitoring-access.yaml'
        }
      }
    }

    stage('RBAC Setup (cluster)') {
      steps {
        container('tools') {
          sh 'kubectl apply -f monitoring/rbac/jenkins-cluster-rbac.yaml'
        }
      }
    }

    stage('Install Prometheus') {
      steps {
        container('tools') {
          sh """
            helm upgrade --install ${PROM_REL} bitnami/kube-prometheus \
              -n ${NAMESPACE} \
              --create-namespace \
              -f monitoring/prometheus/values.yaml \
              --wait
          """
        }
      }
    }

    stage('Provision SMTP (smtp4dev)') {
      steps {
        container('tools') {
          sh "kubectl apply -f monitoring/smtp4dev/smtp4dev.yaml -n ${NAMESPACE}"
        }
      }
    }

    stage('Create Grafana Admin Secret') {
      steps {
        container('tools') {
          sh 'kubectl apply -f monitoring/grafana/grafana-secret.yaml'
        }
      }
    }

    stage('Install Grafana (prebuilt provisioning)') {
      steps {
        container('tools') {
          sh """
            helm upgrade --install grafana bitnami/grafana \
              -n ${NAMESPACE} \
              --create-namespace \
              -f monitoring/grafana/values.yaml \
              --wait
          """
        }
      }
    }

    stage('Status') {
      steps {
        container('tools') {
          sh "kubectl get pods,svc -n ${NAMESPACE}"
        }
      }
    }
  }

  post { always { echo 'Done (Prometheus step).' } }
}
```

---

## 5. RBAC (service account + bindings)

Namespace‑level access for job Pods and a cluster‑admin binding for simplicity in the lab (avoid in prod).

**`monitoring/rbac/jenkins-monitoring-access.yaml`** (excerpt):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-namespace-admin
  namespace: monitoring
rules:
  - apiGroups: ["", "apps", "batch", "extensions"]
    resources: ["*"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-namespace-admin-binding
  namespace: monitoring
subjects:
  - kind: ServiceAccount
    name: jenkins
    namespace: monitoring
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins-namespace-admin
```

**`monitoring/rbac/jenkins-cluster-rbac.yaml`** (excerpt):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-monitoring-admin-binding
subjects:
  - kind: ServiceAccount
    name: jenkins
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

Apply (Jenkins does this automatically; manual check if needed):

```bash
kubectl apply -f monitoring/rbac/jenkins-monitoring-access.yaml
kubectl apply -f monitoring/rbac/jenkins-cluster-rbac.yaml
```

---

## 6. Prometheus (kube‑prometheus)

Install via Helm (Bitnami chart) with exporters:

```bash
helm upgrade --install kube-prometheus bitnami/kube-prometheus \
  -n monitoring --create-namespace \
  -f monitoring/prometheus/values.yaml --wait
```

Check resources:

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

Optional: open Prometheus UI

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-prometheus 9090:9090
# http://localhost:9090
```

Try example queries:

- `node_memory_MemTotal_bytes`
- `node_memory_MemAvailable_bytes`
- `node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes`

---

## 7. SMTP for alerts (smtp4dev)

Deploy the local SMTP server and open its Web UI:

```bash
kubectl apply -f monitoring/smtp4dev/smtp4dev.yaml -n monitoring
kubectl -n monitoring port-forward svc/smtp4dev 8025:80
# http://localhost:8025  (inbox)
```

`smtp4dev` exposes SMTP on port **25** and a Web UI on port **80**.

---

## 8. Grafana (provisioned as code)

### 8.1 Custom Docker image (contains provisioning)

**`monitoring/grafana/docker/Dockerfile`**

```dockerfile
FROM bitnami/grafana:12.1.0

USER root

COPY provisioning/alerting/ /opt/extra-provisioning/alerting/
COPY provisioning/rules/ /opt/extra-provisioning/rules/
COPY provisioning/datasources/ /opt/extra-provisioning/datasources/
COPY provisioning/grafana.ini /opt/extra-provisioning/grafana.ini

RUN mkdir -p /opt/bitnami/grafana/conf/provisioning/alerting \
    && mkdir -p /opt/bitnami/grafana/conf/provisioning/rules \
    && mkdir -p /opt/bitnami/grafana/conf/provisioning/datasources \
    && ln -sfn /opt/extra-provisioning/alerting/contact-points.yaml /opt/bitnami/grafana/conf/provisioning/alerting/contact-points.yaml \
    && ln -sfn /opt/extra-provisioning/alerting/notification-policies.yaml /opt/bitnami/grafana/conf/provisioning/alerting/notification-policies.yaml \
    && ln -sfn /opt/extra-provisioning/alerting/rule-groups.yaml /opt/bitnami/grafana/conf/provisioning/alerting/rule-groups.yaml \
    && ln -sfn /opt/extra-provisioning/datasources/datasources.yaml /opt/bitnami/grafana/conf/provisioning/datasources/datasources.yaml \
    && ln -sfn /opt/extra-provisioning/grafana.ini /opt/bitnami/grafana/conf/grafana.ini \
    && chown -R 1001:1001 /opt/extra-provisioning

USER 1001
```

Build & push (can be done once; Jenkins uses the image):

```bash
docker build -t ihartsykala/grafana-alerting:latest monitoring/grafana/docker
docker push ihartsykala/grafana-alerting:latest
```

### 8.2 Helm values with initContainer

**`monitoring/grafana/values.yaml` (final)**

```yaml
image:
  registry: docker.io
  repository: ihartsykala/grafana-alerting
  tag: latest
  pullPolicy: Always

global:
  security:
    allowInsecureImages: true

grafana:
  imageRenderer:
    enabled: false

  # Copy provisioning files from the custom image to a writable EmptyDir,
  # then mount it into Grafana's official provisioning paths
  initContainers:
    - name: copy-provisioning
      image: ihartsykala/grafana-alerting:latest
      command: [ "/bin/sh", "-c" ]
      args:
        - |
          mkdir -p /provisioning/alerting /provisioning/rules /provisioning/datasources && \
          cp -r /opt/extra-provisioning/alerting/* /provisioning/alerting/ && \
          cp -r /opt/extra-provisioning/rules/* /provisioning/rules/ && \
          cp -r /opt/extra-provisioning/datasources/* /provisioning/datasources/ && \
          cp /opt/extra-provisioning/grafana.ini /provisioning/grafana.ini
      volumeMounts:
        - name: provisioning
          mountPath: /provisioning

  extraVolumes:
    - name: provisioning
      emptyDir: {}

  extraVolumeMounts:
    - name: provisioning
      mountPath: /opt/bitnami/grafana/conf/provisioning
    - name: provisioning
      mountPath: /opt/bitnami/grafana/conf/grafana.ini
      subPath: grafana.ini

admin:
  existingSecret: grafana-secret
  userKey: user
  passwordKey: password

service:
  type: NodePort
  port: 3000
  nodePort: 32000

persistence:
  enabled: true
  size: 1Gi
```

### 8.3 SMTP, datasource & INI (provisioning files)

**`monitoring/grafana/docker/provisioning/grafana.ini` (excerpt):**

```ini
[smtp]
enabled = true
host = smtp4dev.monitoring.svc.cluster.local:25
skip_verify = true
from_address = test@localhost
from_name = Grafana Alerts
```

**`monitoring/grafana/docker/provisioning/datasources/datasources.yaml`:**

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    access: proxy
    url: http://kube-prometheus-prometheus.monitoring.svc.cluster.local:9090
    isDefault: true
```

**`monitoring/grafana/docker/provisioning/alerting/contact-points.yaml`:**

```yaml
apiVersion: 1
contactPoints:
  - orgId: 1
    name: TestEmail
    receivers:
      - uid: testemail-receiver
        type: email
        disableResolveMessage: false
        settings:
          addresses: test@localhost
          singleEmail: false
```

**`monitoring/grafana/docker/provisioning/alerting/notification-policies.yaml`:**

```yaml
apiVersion: 1
policies:
  - orgId: 1
    receiver: TestEmail
    group_by: [alertname]
    continue: false
```

**`monitoring/grafana/docker/provisioning/alerting/rule-groups.yaml` (two rules):**

```yaml
apiVersion: 1
groups:
  - orgId: 1
    name: Every 10s
    folder: ClusterAlerts
    interval: 10s
    rules:
      - uid: high-cpu-usage
        title: High CPU Usage
        condition: C
        data:
          - refId: A
            relativeTimeRange: { from: 600, to: 0 }
            datasourceUid: prometheus
            model:
              editorMode: code
              expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
              instant: true
              range: false
              refId: A
          - refId: C
            datasourceUid: __expr__
            model:
              conditions:
                - evaluator: { params: [80], type: gt }
                  operator: { type: and }
                  query: { params: [C] }
                  reducer: { type: last }
                  type: query
              expression: A
              refId: C
              type: threshold
        noDataState: NoData
        execErrState: Error
        for: 10s
        keepFiringFor: 10s
        isPaused: false
        notification_settings: { receiver: TestEmail }

      - uid: lack-of-ram
        title: Lack of RAM capacity
        condition: C
        data:
          - refId: A
            relativeTimeRange: { from: 600, to: 0 }
            datasourceUid: prometheus
            model:
              editorMode: code
              expr: 100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
              instant: true
              range: false
              refId: A
          - refId: C
            datasourceUid: __expr__
            model:
              conditions:
                - evaluator: { params: [80], type: gt }
                  operator: { type: and }
                  query: { params: [C] }
                  reducer: { type: last }
                  type: query
              expression: A
              refId: C
              type: threshold
        noDataState: NoData
        execErrState: Error
        for: 10s
        keepFiringFor: 10s
        isPaused: false
        notification_settings: { receiver: TestEmail }
```

### 8.4 Admin secret & install

Create the admin secret (Jenkins also applies it):

```bash
kubectl apply -n monitoring -f monitoring/grafana/grafana-secret.yaml
```

Deploy Grafana with the values above:

```bash
helm upgrade --install grafana bitnami/grafana \
  -n monitoring --create-namespace \
  -f monitoring/grafana/values.yaml --wait
```

Access the UI:

```bash
# Option 1: port-forward
kubectl -n monitoring port-forward svc/grafana 3000:3000
# http://localhost:3000

# Option 2: NodePort (configured to 32000)
# http://NODE-IP:32000
```

Login: `admin` / `<password from grafana-secret.yaml>` (example: `securePassword123`).

---

## 9. Validation

### 9.1 Pods and services

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### 9.2 Sample Prometheus queries

Open Prometheus (port‑forward 9090) and run:

- `node_memory_MemAvailable_bytes`
- `node_memory_MemTotal_bytes`
- `100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))`

### 9.3 Trigger alerts

Run CPU and RAM stress pods to trigger rules:

```bash
kubectl run cpu-stress --rm -i --tty \
  --image=progrium/stress -- \
  stress --cpu 4 --timeout 300

kubectl run mem-stress --rm -i --tty \
  --image=progrium/stress -- \
  stress --vm 1 --vm-bytes 512M --timeout 300
```

Watch Grafana: *Alerting → Alert rules* should go **FIRING**, then **RESOLVED**.

### 9.4 Check e‑mail notifications

Open smtp4dev UI:

```bash
kubectl -n monitoring port-forward svc/smtp4dev 8025:80
# http://localhost:8025
```

You should see messages like:

- `[FIRING:1] High CPU Usage ...`
- `[FIRING:1] Lack of RAM capacity ...`
- `[RESOLVED] ...`

---

## 10. Troubleshooting Notes

- **Pipeline ran a wrong Jenkinsfile** (from Task 6): set **Script Path** to `monitoring/Jenkinsfile`.
- **`Invalid option type "timestamps"`**: remove `timestamps()` or install the Timestamper plugin.
- **Kubernetes plugin “label is deprecated”**: informational for this lab.
- **No e‑mails**: check `grafana.ini` SMTP host, smtp4dev service DNS, and that `smtp4dev` pod is running.
- **Grafana didn’t load provisioning**: ensure the `initContainer` completed and `extraVolumeMounts` point to `/opt/bitnami/grafana/conf/provisioning`.
- **Prometheus unreachable**: verify service name `kube-prometheus-prometheus` and namespace.
- **NodePort 32000 busy**: change `service.nodePort` in `values.yaml` or use `port-forward`.

---

## 11. What this delivers

- ✅ Prometheus + exporters installed via Helm (`bitnami/kube-prometheus`)
- ✅ Grafana installed via Helm, **preconfigured** by a custom image + `initContainer`
- ✅ SMTP (smtp4dev) for local alert e‑mail testing
- ✅ Contact Points, Notification Policy, and **two alert rules** provisioned as YAML
- ✅ Jenkins **only** deployment flow (manual run / `Poll SCM`)
- ✅ Dashboard JSON included and persistence enabled

---

## 12. Appendix

### 12.1 Grafana admin secret (example)

`monitoring/grafana/grafana-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-secret
  namespace: monitoring
type: Opaque
stringData:
  user: admin
  password: securePassword123
```

### 12.2 Prometheus values

`monitoring/prometheus/values.yaml` – minimal overrides (use defaults unless you need custom retention/resources).

```yaml
kubeStateMetrics:
  enabled: true

nodeExporter:
  enabled: true

alertmanager:
  enabled: true

prometheus:
  retention: 15d
```

### 12.3 Dashboard JSON

`monitoring/grafana/dashboards/node-metrics.json` – can be imported in Grafana (Data source UID: `prometheus`).

### 12.4 Useful one‑liners

```bash
# All resources in the namespace
kubectl get all -n monitoring

# Logs from Grafana
kubectl logs -n monitoring deploy/grafana

# Reinstall Grafana cleanly (for dev/testing)
helm uninstall grafana -n monitoring
kubectl delete pod -n monitoring -l app.kubernetes.io/name=grafana --force --grace-period=0
helm upgrade --install grafana bitnami/grafana -n monitoring -f monitoring/grafana/values.yaml --wait
```

**Everything above is reproducible with:**
1. Start Minikube → Install Jenkins via Helm → Configure job (`Poll SCM`)
2. Run the job → RBAC → kube‑prometheus → smtp4dev → Grafana (with provisioning)
3. Validate in Prometheus/Grafana, trigger alerts, confirm e‑mails in smtp4dev

**Deployment is 100% code‑driven and idempotent.**
