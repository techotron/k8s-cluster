# k8s-cluster

Create a kubernetes cluster in AWS

## Deploy K8s cluster

From the ./Deploy directory:

Run the `./k8s-deploy.sh` to deploy a cluster in your AWS account. Some variables will need to be changed in order to work for you.

**Note:** This will attempt to create a certificate for the KubernetesDNS name. The validation method in the CFN template is `DNS` so you'll need to go to the ACM and create the necessary DNS records before the CFN stack finishes

Run the `./k8s-setup.sh` to setup the cluster with the ops namespace and install helm/tiller. 

## Update K8s cluster

This will update changes to the CFN stacks and kops manifest

```bash
./k8s-setup.sh update
```

## Delete the KOPS K8s Cluster

This will delete the KOPS deployed resources only. It will not delete the resources deployed via `./Infrastructure/CFN-Environment.yaml` or `./Infrastructure/CFN-kops.yaml`

The cost of Environement and Kops stacks is next to nothing so it's convenient to keep them running, whilst deploy/deleting the kops environment as and when needed.

## Infrastructure

Defined in the ./Manifest/lab.kube.esnow.uk.yaml file


## Kops image:k8s version relationship

https://github.com/kubernetes/kops/blob/master/channels/stable






# TODO
- Deploy Jenkins Helm chart: https://github.com/helm/charts/tree/master/stable/jenkins
- Create job to deploy helm charts
- Deploy Prometheus helm chart: https://github.com/helm/charts/tree/master/stable/prometheus
- Create cluster auto scaler: https://github.com/helm/charts/tree/master/stable/cluster-autoscaler
- Automate kubernetes version to image relationship lookup
