#!/usr/bin/env bash

# Useful commands
# Upload the key to the bastion host in order to log onto the nodes
#scp -i ~/.ssh/k8s_id_rsa ~/.ssh/k8s_id_rsa admin@bastion-eddy.eu.sbx.kube.intapp.com:~/.ssh/k8s_id_rsa

# SSH onto a node
#ssh -A -i ~/.ssh/k8s_id_rsa admin@<nodeIP>

# !!!NOTE!!!
# Dashboard password is: Password01 (it can be generated using htpasswd

echo "[$(date)] - Applying namespace"
kubectl apply -f ../Namespaces/ops.yaml

echo "[$(date)] - Setting up helm"
kubectl apply -f ../Authorization/helm/helm_ops.yaml

echo "[$(date)] - Installing tiller"
helm init --service-account tiller --tiller-namespace=ops

echo "[$(date)] - Setting up nginx ingress controller"
helm upgrade -i -f ../Helm/ingress-nginx/values.yaml --wait --timeout 60 ingress-nginx stable/nginx-ingress --tiller-namespace=ops --namespace=ops

# !!!NOTE!!!
# Need to add AWS alias for each service to the ELB created in the above deployment

echo "[$(date)] - Install wordpress"
helm upgrade -i -f ../Helm/wordpress/values.yaml --wait --timeout 120 wordpress stable/wordpress --tiller-namespace=ops --namespace=ops

echo "[$(date)] - Install grafana"
helm upgrade -i -f ../Helm/grafana/values.yaml --wait --timeout 60 grafana stable/grafana --tiller-namespace=ops --namespace=ops

echo "[$(date)] - Install prometheus"
helm upgrade -i -f ../Helm/prometheus/values.yaml --wait --timeout 120 prometheus stable/prometheus --tiller-namespace=ops --namespace=ops

echo "[$(date)] - Install jenkins"
helm upgrade -i -f ../Helm/jenkins/values.yaml --wait --timeout 400 jenkins stable/jenkins --tiller-namespace=ops --namespace=ops

#simple-site
#helm upgrade simple-site ../Helm/simple-site --namespace default --tiller-namespace=default --install