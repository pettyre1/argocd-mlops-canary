.PHONY: help setup teardown start-cluster install-tools build apply-bootstrap get-argo-pass port-forward-argo port-forward-prom port-forward-app

# Variables
IMAGE_NAME := local/nlp-api:latest
MEMORY := 2048
CPUS := 2 

# Default target when just running 'make'
help:
	@echo "MLOps GitOps Local Cluster Setup"
	@echo "--------------------------------"
	@echo "Commands:"
	@echo "  make setup             - Tears down (if exists), starts Minikube, installs tools, and deploys"
	@echo "  make teardown          - Destroys the Minikube cluster"
	@echo "  make build             - Rebuilds the FastAPI Docker image inside Minikube"
	@echo "  make port-forward-argo - Forwards ArgoCD UI to localhost:8080"
	@echo "  make port-forward-prom - Forwards Prometheus UI to localhost:9090"
	@echo "  make port-forward-app  - Forwards the NLP API to localhost:8000"
	@echo "  make get-argo-pass     - Retrieves the initial ArgoCD admin password"

setup: teardown start-cluster install-tools build apply-bootstrap get-argo-pass
	@echo "\nCluster setup complete! Run 'make help' for port-forwarding commands."

teardown:
	@echo "Destroying Minikube cluster..."
	minikube delete || true

start-cluster:
	@echo "Starting Minikube cluster ($(CPUS) CPUs, $(MEMORY)MB RAM)..."
	minikube start --cpus $(CPUS) --memory $(MEMORY)

install-tools:
	@echo "Creating namespaces..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
	
	@echo "Installing ArgoCD & Argo Rollouts..."
	kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl apply -n argo-rollouts --server-side -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
	
	@echo "Installing Prometheus Stack via Helm..."
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade --install prometheus prometheus-community/prometheus --namespace default \
		--set alertmanager.enabled=false \
		--set pushgateway.enabled=false \
		--set nodeExporter.enabled=false \
		--set kubeStateMetrics.enabled=false
	
	@echo "Waiting for ArgoCD pods to be ready..."
	kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

build:
	@echo "Building the local Docker image locally..."
	cd app && docker build -t pettyre1/nlp-api:latest .
	docker push pettyre1/nlp-api:latest

apply-bootstrap:
	@echo "Applying GitOps Bootstrap Application..."
	@if [ -f "bootstrap.yaml" ]; then kubectl apply -f bootstrap.yaml; else echo "bootstrap.yaml not found!"; fi

get-argo-pass:
	@echo "\nArgoCD Admin Password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
	@echo ""

port-forward-argo:
	@echo "ArgoCD UI running on http://localhost:8080 (Ctrl+C to stop)..."
	kubectl port-forward svc/argocd-server -n argocd 8080:443

port-forward-prom:
	@echo "Prometheus running on http://localhost:9090 (Ctrl+C to stop)..."
	kubectl port-forward svc/prometheus-server 9090:80

port-forward-app:
	@echo "NLP API running on http://localhost:8000 (Ctrl+C to stop)..."
	kubectl port-forward svc/nlp-api-service 8000:80
