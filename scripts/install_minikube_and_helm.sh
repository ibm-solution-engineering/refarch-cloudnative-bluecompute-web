#!/bin/bash

# Install socat, which is neede for port-forwarding
sudo apt-get update
sudo apt-get install socat

# Download kubectl, which is a requirement for using minikube.
KUBERNETES_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Download minikube.
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.1.0/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
# Start minikube
sudo minikube start --vm-driver=none --kubernetes-version=$KUBERNETES_VERSION
# Update minikube direcotry permissions
sudo chown -R travis: /home/travis/.minikube/
# Fix the kubectl context, as it's often stale.
minikube update-context
# Getting ip for testing
minikube ip
# Wait for Minikube to be up and ready.
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done

# Download helm
curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
# rm get_helm.sh
# Create Tiller Service Account
kubectl -n kube-system create sa tiller && kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
# Install Helm on Minikube
helm init --service-account tiller
# Wait for helm to be ready
until helm list; do echo "waiting for helm to be ready"; sleep 1; done
# Then show helm version
helm version

# Add incubator and bluecompute-charts Helm repos
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
# helm repo add ibmcase-charts https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts

# Get cluster info
kubectl cluster-info
