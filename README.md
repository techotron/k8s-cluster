# k8s-cluster
Create a kubernetes cluster in AWS

## Deploy K8s cluster
From the ./Deploy directory:

Run the `./k8s-deploy.sh` to deploy a cluster in the devops sandbox AWS account. Some variables will need to be changed in order to work for you.

Run the `./k8s-setup.sh` to setup the cluster with the ops namespace and install helm/tiller. 

## Update K8s cluster
This will update changes to the CFN stacks and kops manifest
```bash
./k8s-setup.sh update
```


## Infrastructure
Defined in the ./Manifest/eu-eddy.sbx.kube.intapp.com.yaml file







# TODO
1. Deploy Jenkins Helm chart: https://github.com/helm/charts/tree/master/stable/jenkins
2. Create job to deploy helm charts
3. Deploy Prometheus helm chart: https://github.com/helm/charts/tree/master/stable/prometheus
4. Create cluster auto scaler: https://github.com/helm/charts/tree/master/stable/cluster-autoscaler
