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
      image: ihartsykala/docker-helm-minikube:latest
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

     stage('Deploy to K8s with Helm') {
          when {
            beforeAgent true
            triggeredBy 'UserIdCause'
          }
          steps {
            container('docker') {
              dir('app') {
                sh """
                  echo "🚀 Deploying with Helm..."
                  helm upgrade --install node-hello ../kubernetes/node-app \
                    --set image.repository=ihartsykala/node-hello \
                    --set image.tag=${BUILD_NUMBER}
                  echo "✅ Deployed node-hello to Kubernetes"
                """
              }
            }
          }
        }

       stage('Verify Application') {
         steps {
           container('docker') {
             sh '''
               echo "🔍 Verifying application..."
               RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://node-hello-node-app.jenkins.svc.cluster.local)
               if [ "$RESPONSE" -ne 200 ]; then
                 echo "❌ Verification failed. Status code: $RESPONSE"
                 echo "📋 Pods:"
                 kubectl get pods -n jenkins || true
                 echo "📋 Logs:"
                 kubectl logs -n jenkins -l app=node-hello-node-app --tail=100 || true
                 exit 1
               fi
               echo "✅ Application verification passed with status $RESPONSE"
             '''
           }
         }
       }

  }

  post {
    success {
      echo '✅ Pipeline passed'
      container('docker') {
        withCredentials([
          string(credentialsId: 'TELEGRAM_TOKEN', variable: 'TG_TOKEN'),
          string(credentialsId: 'TELEGRAM_CHAT_ID', variable: 'TG_CHAT')
        ]) {
          sh """
            curl -s -X POST https://api.telegram.org/bot$TG_TOKEN/sendMessage \\
              -d chat_id=$TG_CHAT \\
              -d text="✅ Jenkins pipeline succeeded: Job '$JOB_NAME' #$BUILD_NUMBER"
          """
        }
      }
    }

    failure {
      echo '❌ Pipeline failed'
      container('docker') {
        withCredentials([
          string(credentialsId: 'TELEGRAM_TOKEN', variable: 'TG_TOKEN'),
          string(credentialsId: 'TELEGRAM_CHAT_ID', variable: 'TG_CHAT')
        ]) {
          sh """
            curl -s -X POST https://api.telegram.org/bot$TG_TOKEN/sendMessage \\
              -d chat_id=$TG_CHAT \\
              -d text="❌ Jenkins pipeline failed: Job '$JOB_NAME' #$BUILD_NUMBER"
          """
        }
      }
    }
  }

}
