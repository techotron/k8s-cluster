# k8s-cluster

Create a kubernetes cluster in AWS

## Deploy K8s cluster

From the ./Deploy directory:

Run the `./k8s-deploy.sh` to deploy a cluster in your AWS account. Some variables will need to be changed in order to work for you.

**Note:** This will attempt to create a certificate for the KubernetesDNS name. The validation method in the CFN template is `DNS` so you'll need to go to the ACM and create the necessary DNS records before the CFN stack finishes
**TODO:** Automate ACM validation using CFN: https://aws.amazon.com/about-aws/whats-new/2020/06/aws-certificate-manager-extends-automation-certificate-issuance-via-cloudformation/

### Deploy HA Cluster

This will deploy a K8s cluster with master nodes in HA

`./k8s-deploy.sh create ha`

or 

`./k8s-deploy.sh update ha`

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

Defined in the `./Manifest/cluster-template.yaml` and `./Manifest/ha-cluster-template.yaml` files

## Kops image:k8s version relationship

https://github.com/kubernetes/kops/blob/master/channels/stable

## AWS Domain Setup

These are the steps to setup your own domain using Route53. Although not a requirement, I'll go through setting up child domains in which to keep K8s resources in. These will be _kube.DOMAIN.TLD_ and _lab.kube.DOMAIN.TLD_. You don't have to use these names but will require a minor change to the [k8s-deploy.sh](./k8s-deploy.sh)

1. Within the Route53 console, click on **Registered Domains** -> **Register Domain** and follow the setup guide for registering your own domain.
1. Once the new domain is registered, open **Hosted Zones** and click on **Create Hosted Zone**. Enter the full domain, eg "kube.snowco.uk", leave the tpye as "Public" and click **Create**.
1. Open the new hosted zone and copy the values of the **NS** (Nameserver) records (there will be about 4 of them).
1. Go back to the list of hosted zones and open the root domain, eg "snowco.uk".
1. Create a new record set with a name of "kube" and type of "NS" and paste the list of name servers you copied a few steps ago.
1. Repeat the steps above for a new child domain eg, "lab.kube.snowco.uk" but create the new NS records in the "kube.snowco.uk" parent domain.

**Note:** These changes will take a bit of time to propergate. 





# TODO
- Deploy Jenkins Helm chart: https://github.com/helm/charts/tree/master/stable/jenkins
- Create job to deploy helm charts
- Deploy Prometheus helm chart: https://github.com/helm/charts/tree/master/stable/prometheus
- Create cluster auto scaler: https://github.com/helm/charts/tree/master/stable/cluster-autoscaler
- Automate kubernetes version to image relationship lookup
