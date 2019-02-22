#!/usr/bin/env bash

# Useful commands
# Upload the key to the bastion host in order to log onto the nodes
#scp -i ~/.ssh/k8s_id_rsa ~/.ssh/k8s_id_rsa admin@bastion-eddy.eu.sbx.kube.intapp.com:~/.ssh/k8s_id_rsa

# SSH onto a node
#ssh -A -i ~/.ssh/k8s_id_rsa admin@<nodeIP>

# !!!NOTE!!!
# Need to update the record which gets created: "api.internal.eddy.eu.sbx.kube.intapp.com." to be an Alias and point to the same value as "api-eddy.eu.sbx.kube.intapp.com."
# Dashboard password is: Password01 (it can be generated using htpasswd

export DOCKER_PASS="<lastpass>"

echo "[$(date)] - Applying namespace"
kubectl apply -f /Users/eddys/git/k8s-cluster/Namespaces/ops.yaml

echo "[$(date)] - Adding secret for docker registry in artifactory"
kubectl create secret docker-registry artifactory --docker-server=docker.artifactory.dev.intapp.com --docker-username=k8s_dev --docker-password=$DOCKER_PASS --docker-email=devops.dev@intapp.com

echo "[$(date)] - Setting up helm"
kubectl apply -f /Users/eddys/git/k8s-cluster/Authorization/helm/helm_default.yaml
kubectl apply -f /Users/eddys/git/k8s-cluster/Authorization/helm/helm_ops.yaml
kubectl apply -f /Users/eddys/git/k8s-cluster/Authorization/helm/helm_kube-system.yaml
kubectl apply -f /Users/eddys/git/k8s-cluster/Authorization/helm/helm_kube-public.yaml

echo "[$(date)] - Installing tiller"
helm init --service-account tiller --tiller-namespace ops
helm init --service-account tiller --tiller-namespace default
helm init --service-account tiller --tiller-namespace kube-system
helm init --service-account tiller --tiller-namespace kube-public

#echo "[$(date)] - Setting up traefik ingress - external"
#helm upgrade --install -f /Users/eddys/git/k8s-cluster/Ingress/external.yaml  \
# --set dashboard.domain="traefik-external-eddy.eu.sbx.kube.intapp.com" \
# --set service.annotations.service.beta.kubernetes.io/aws-load-balancer-ssl-cert="arn:aws:acm:eu-west-1:278942993584:certificate/1dcb38ff-8b2a-4d27-afba-b33fb3a04a51" \
# --set service.annotations.service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags="Product=Kubernetes-Cluster\,Environment=DEV\,ProductComponents=ELB\,Contact=eddy.snow@intapp.com\,Team=DevOps" \
# --namespace ops \
# --tiller-namespace ops \
# traefik-external \
# helm-incubator/traefik

echo "[$(date)] - Setting up traefik ingress - external tls"
helm upgrade --install -f /Users/eddys/git/k8s-cluster/Ingress/external-tls.yaml \
 --set dashboard.domain="traefik-externaltls-eddy.eu.sbx.kube.intapp.com" \
 --set dashboard.auth.basic.devops='$apr1$u4OmhmyX$V8/V8o/QNH7Cjq6bONf900' \
 --set service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"="arn:aws:acm:eu-west-1:278942993584:certificate/1dcb38ff-8b2a-4d27-afba-b33fb3a04a51" \
 --set service.annotations.service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags="Product=Kubernetes-Cluster\,Environment=DEV\,ProductComponents=ELB\,Contact=eddy.snow@intapp.com\,Team=DevOps" \
 --set kubernetes.labelSelector="traffic-type=traefik-external-tls" \
 --set dashboard.ingress.labels.traffic-type="traefik-external-tls" \
 --namespace ops \
 --tiller-namespace ops \
 traefik-external-tls \
 helm-incubator/traefik


#echo "[$(date)] - Setting up traefik ingress - internal"
#helm upgrade --install -f /Users/eddys/git/k8s-cluster/Ingress/internal.yaml  \
#--set dashboard.domain="traefik-internal-eddy.eu.sbx.kube.intapp.com" \
#--set service.annotations.service.beta.kubernetes.io/aws-load-balancer-ssl-cert="arn:aws:acm:eu-west-1:278942993584:certificate/1dcb38ff-8b2a-4d27-afba-b33fb3a04a51" \
#--set service.annotations.service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags="Product=Kubernetes-Cluster,Environment=DEV,ProductComponents=ELB,Contact=eddy.snow@intapp.com,Team=DevOps" \
#--namespace ops \
#--tiller-namespace ops \
#traefik-internal \
#helm-incubator/traefik
