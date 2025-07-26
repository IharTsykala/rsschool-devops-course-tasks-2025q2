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

    stage('RBAC Setup') {
      steps {
        container('tools') {
          sh 'kubectl apply -f monitoring/rbac/jenkins-monitoring-access.yaml'
        }
      }
    }

    stage('Cluster RBAC Setup') {
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

    stage('Install Grafana') {
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
