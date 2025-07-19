pipeline {
  agent {
    kubernetes {
      label 'nodejs'
      defaultContainer 'node'
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    job: nodejs-build
spec:
  containers:
  - name: node
    image: node:lts-alpine
    command: ["sh", "-c", "cat"]
    tty: true
"""
    }
  }

  triggers {
    pollSCM('H/2 * * * *')
  }

  environment {
    IMAGE = "ihartsykala/node-hello:${env.BUILD_NUMBER}"
  }

  stages {
    stage('Build') {
      steps {
        container('node') {
          dir('app') {
            sh 'echo "Node version:"'
            sh 'node -v'
            sh 'npm ci'
          }
        }
      }
    }
  }

  post {
    success { echo '✅ Pipeline passed' }
    failure { echo '❌ Pipeline failed' }
  }
}
