FROM docker:24.0.5-cli

RUN apk add --no-cache bash curl git openssl \
  && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
  && curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && install minikube-linux-amd64 /usr/local/bin/minikube \
  && rm minikube-linux-amd64
