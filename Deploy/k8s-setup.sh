#!/usr/bin/env bash

# Useful commands
# Upload the key to the bastion host in order to log onto the nodes
#scp -i ~/.ssh/k8s_id_rsa ~/.ssh/k8s_id_rsa admin@bastion-eddy.eu.sbx.kube.intapp.com:~/.ssh/k8s_id_rsa

# SSH onto a node
#ssh -A -i ~/.ssh/k8s_id_rsa admin@<nodeIP>

# !!!NOTE!!!
# Dashboard password is: Password01 (it can be generated using htpasswd

echo "[$(date)] - Applying namespace"
kubectl apply -f ../Namespaces/default.yaml

echo "[$(date)] - Setting up helm"
kubectl apply -f ../Authorization/helm/helm_default.yaml

echo "[$(date)] - Installing tiller"
helm init --service-account tiller --tiller-namespace=default

echo "[$(date)] - Setting up nginx ingress controller"
helm upgrade -i -f ../Helm/ingress-nginx/values.yaml --wait --timeout 300 ingress-nginx stable/nginx-ingress --tiller-namespace=default

# !!!NOTE!!!
# Need to add AWS alias for each service to the ELB created in the above deployment

echo "[$(date)] - Install grafana"
helm upgrade -i -f ../Helm/grafana/values.yaml --wait --timeout 600 grafana stable/grafana --tiller-namespace=default

echo "[$(date)] - Install prometheus"
helm upgrade -i -f ../Helm/prometheus/values.yaml --wait --timeout 600 prometheus stable/prometheus --tiller-namespace=default

echo "[$(date)] - Install jenkins"
helm upgrade -i -f ../Helm/jenkins/values.yaml --wait --timeout 600 jenkins stable/jenkins --tiller-namespace=default