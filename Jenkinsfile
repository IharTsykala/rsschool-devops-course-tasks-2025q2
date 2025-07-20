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
    - name: docker
      image: docker:latest
      command: ["sh", "-c", "cat"]
      tty: true
      volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
  volumes:
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
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

    stage('Docker Build (local Minikube)') {
      when {
        beforeAgent true
        triggeredBy 'UserIdCause'
      }
      steps {
        container('docker') {
          dir('app') {
            sh '''
              echo "🔧 Switching to Minikube Docker..."
              eval $(minikube docker-env)
              echo "🐳 Building Docker image..."
              docker build -t $IMAGE .
              echo "✅ Docker image $IMAGE built in Minikube Docker daemon"
            '''
          }
        }
      }
    }

    stage('Push Docker Image to Docker Hub') {
      when {
        beforeAgent true
        triggeredBy 'UserIdCause'
      }
      steps {
        container('docker') {
          dir('app') {
            withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
              sh '''
                echo "📦 Logging into Docker Hub..."
                echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                echo "📤 Pushing Docker image to Docker Hub..."
                docker push $IMAGE
                echo "✅ Docker image pushed: $IMAGE"
              '''
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
