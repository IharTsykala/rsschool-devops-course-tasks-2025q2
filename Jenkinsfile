pipeline {
  agent {
    kubernetes {
      label 'monitoring'
      defaultContainer 'tools'
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: tools
      image: ihartsykala/docker-helm-minikube:latest
      command: ["sh", "-c", "sleep 36000"]
      tty: true
"""
    }
  }

  triggers { pollSCM('H/2 * * * *') }

  options {
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
    // timestamps()
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Sanity') {
      steps {
        container('tools') {
          sh '''
            echo "✅ Pipeline skeleton is alive. Workspace: $PWD"
            echo "Tools availability check (no cluster changes):"
            helm version --short || true
            kubectl version --client --short || true
          '''
        }
      }
    }
  }

  post {
    always { echo 'Done.' }
  }
}
