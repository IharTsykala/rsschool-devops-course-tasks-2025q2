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
    - name: sonarscanner
      image: sonarsource/sonar-scanner-cli:latest
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

    stage('Test') {
      steps {
        echo '⚠️ Entered test stage'
        container('node') {
          dir('app') {
            sh 'node --experimental-vm-modules node_modules/.bin/jest'
          }
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        container('sonarscanner') {
          dir('app') {
            withSonarQubeEnv('MySonarQube') {
              sh 'sonar-scanner -Dsonar.host.url=http://sonarqube.jenkins.svc.cluster.local:9000'
            }
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
