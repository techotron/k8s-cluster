#!/usr/bin/env bash

if [ "$1" = "update" ]; then
    DEPLOY_TYPE="update"
elif [ "$1" = "create" ]; then
    DEPLOY_TYPE="create"
elif [ "$1" = "create_deps" ]; then
    DEPLOY_TYPE="create_deps"
else
    DEPLOY_TYPE="create"
fi

if [ "$2" = "ha" ]; then
    HA="true"
else
    HA="false"
fi

AWS_PROFILE="snowco"
AWS_REGION="eu-west-2"
NAME="lab"
K8S_STACK_NAME="k8s-lab"
K8S_DNS_DOMAIN="kube.esnow.uk"
K8S_IAM_NAME="$K8S_STACK_NAME-iam"
K8S_ENV_NAME="$K8S_STACK_NAME-env"
KOPS_CONFIG_VERSION=$(date +%F_%H%M%S)
CLUSTER_NAME="$NAME.$K8S_DNS_DOMAIN"
K8S_NETWORK="10.10"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text --profile $AWS_PROFILE)
CLUSTER_STATE_BUCKET="$AWS_ACCOUNT_ID-k8s-clst-state-$K8S_ENV_NAME-$AWS_REGION"

echo "[$(date)] - Deploying stacks to region: $AWS_REGION"

# Might need to create manually with a passphrase: ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s_id_rsa
echo "[$(date)] - Creating new PKI secret unless it already exists"
if [ ! -f ~/.ssh/k8s_id_rsa ]; then
    echo "[$(date)] - Secret not found, creating now"
    ssh-keygen -t rsa -b 4096 -N 'k8s_id_rsa' -f ~/.ssh/k8s_id_rsa
fi

echo "[$(date)] - iam stack"
aws cloudformation deploy \
    --stack-name $K8S_IAM_NAME \
    --template-file ../Infrastructure/CFN-kops.yaml \
    --parameter-overrides \
        AccessKeyRotation=0 \
    --profile $AWS_PROFILE \
    --region $AWS_REGION \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM;

echo "[$(date)] - environment stack"
aws cloudformation deploy --stack-name $K8S_ENV_NAME \
    --template-file ../Infrastructure/CFN-Environment.yaml \
    --parameter-overrides \
        Network=$K8S_NETWORK \
        KubernetesDNS=$K8S_DNS_DOMAIN \
        Environment="dev" \
        LoggerAccessKeyRotation=0 \
    --profile $AWS_PROFILE \
    --region $AWS_REGION \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM;

echo "[$(date)] - Exporting KOPS IAM credentials for KOPS related AWS tasks"
export AWS_ACCESS_KEY_ID=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="AccessKeyId").OutputValue')
export AWS_SECRET_ACCESS_KEY=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="SecretAccessKey").OutputValue')

echo "[$(date)] - Exporting AWS resources to feed into manifest template"
export K8S_DNS_FULL_DOMAIN="$NAME.$K8S_DNS_DOMAIN."
export K8S_VPC_ID=$(aws ec2 describe-vpcs --region $AWS_REGION --query 'Vpcs[?Tags[?Key==`Name`]|[?Value==`k8s-cluster`]].VpcId' --output text)
export AWS_HOSTED_ZONE_ID=$(aws route53 list-hosted-zones | jq '.HostedZones[] | select(.Name == env.K8S_DNS_FULL_DOMAIN).Id' | tr -d '"','' | tr -d '/hostedzone','')


echo "[$(date)] - Backing up old KOPS configuration"
aws s3 cp s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME/instancegroup s3://$CLUSTER_STATE_BUCKET/$KOPS_CONFIG_VERSION/$CLUSTER_NAME/instancegroup/ --recursive --profile $AWS_PROFILE
aws s3 cp s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME/config s3://$CLUSTER_STATE_BUCKET/$KOPS_CONFIG_VERSION/$CLUSTER_NAME --profile $AWS_PROFILE
aws s3 rm s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME/instancegroup/ --recursive --profile $AWS_PROFILE
aws s3 rm s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME/config --profile $AWS_PROFILE

echo "[$(date)] - Creating KOPS configuration and uploading to s3"
if [ "$HA" = "false" ]; then
    kops toolbox template --template ../Manifest/cluster-template.yaml \
        --values ../Manifest/cluster-config.yaml \
        --fail-on-missing \
        --format-yaml=true > ../Manifest/cluster-manifest.yaml \
            --set "name=$NAME,dnsZone=$K8S_DNS_DOMAIN,aws.region=$AWS_REGION,aws.networkAddress=$K8S_NETWORK,aws.vpcId=$K8S_VPC_ID,awsDnsZoneId=$AWS_HOSTED_ZONE_ID,clusterStateStorage=s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME"
elif [ "$HA" = "true" ]; then
    kops toolbox template --template ../Manifest/ha-cluster-template.yaml \
        --values ../Manifest/cluster-config.yaml \
        --fail-on-missing \
        --format-yaml=true > ../Manifest/cluster-manifest.yaml \
            --set "name=$NAME,dnsZone=$K8S_DNS_DOMAIN,aws.region=$AWS_REGION,aws.networkAddress=$K8S_NETWORK,aws.vpcId=$K8S_VPC_ID,awsDnsZoneId=$AWS_HOSTED_ZONE_ID,clusterStateStorage=s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME"
fi

if [ "$DEPLOY_TYPE" = "create_deps" ]; then
    echo "[$(date)] - Dependancies deployed - nothing else to do"
    exit 0
fi

kops create -f ../Manifest/cluster-manifest.yaml --state="s3://"$CLUSTER_STATE_BUCKET


if [ "$DEPLOY_TYPE" = "update" ]; then
    echo "[$(date)] - This is an update, no need to create a new pki secret"
elif [ "$DEPLOY_TYPE" = "create" ]; then
    echo "[$(date)] - Creating pki secret and uploading to s3"
    kops create secret --name $CLUSTER_NAME sshpublickey admin -i ~/.ssh/k8s_id_rsa.pub --state="s3://"$CLUSTER_STATE_BUCKET
fi


echo "[$(date)] - Deploy the cluster"
kops update cluster $CLUSTER_NAME --yes \
    --state="s3://"$CLUSTER_STATE_BUCKET