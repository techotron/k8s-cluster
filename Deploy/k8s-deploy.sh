#!/usr/bin/env bash


# TODO:
# 1. Use kops toolbox template to modifiy the kops manifest



if [ "$1" = "update" ]; then
    DEPLOY_TYPE="update"
elif [ "$1" = "create" ]; then
    DEPLOY_TYPE="create"
elif [ "$1" = "create_deps" ]; then
    DEPLOY_TYPE="create_deps"
else
    DEPLOY_TYPE="create"
fi

AWS_PROFILE="snowco"
AWS_REGION="eu-west-1"
K8S_STACK_NAME="k8s-lab"
K8S_IAM_NAME="$K8S_STACK_NAME-iam"
K8S_ENV_NAME="$K8S_STACK_NAME-env"
K8S_DNS_DOMAIN="kube.esnow.uk"
KOPS_CONFIG_VERSION=$(date +%F_%H%M%S)
#S3_CONFIG_BUCKET_URL="https://s3-eu-west-1.amazonaws.com/722777194664-kops-eu-west-1/git/k8s-cluster/"
CLUSTER_NAME="lab.kube.esnow.uk"
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
        Network="10.10" \
        KubernetesDNS=$K8S_DNS_DOMAIN \
        Environment="dev" \
        LoggerAccessKeyRotation=0 \
    --profile $AWS_PROFILE \
    --region $AWS_REGION \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM;

echo "[$(date)] - Exporting KOPS IAM credentials for KOPS related AWS tasks"
export AWS_ACCESS_KEY_ID=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="AccessKeyId").OutputValue')
export AWS_SECRET_ACCESS_KEY=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="SecretAccessKey").OutputValue')

echo "[$(date)] - Backing up old KOPS configuration"
aws s3 cp s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME/instancegroup s3://$CLUSTER_STATE_BUCKET/$KOPS_CONFIG_VERSION/$CLUSTER_NAME/instancegroup/ --recursive --profile $AWS_PROFILE
aws s3 cp s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME/config s3://$CLUSTER_STATE_BUCKET/$KOPS_CONFIG_VERSION/$CLUSTER_NAME --profile $AWS_PROFILE
aws s3 rm s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME/instancegroup/ --recursive --profile $AWS_PROFILE
aws s3 rm s3://$CLUSTER_STATE_BUCKET/$CLUSTER_NAME/config --profile $AWS_PROFILE

echo "[$(date)] - Creating KOPS configuration and uploading to s3"
kops create -f ../Manifest/lab.kube.esnow.uk.yaml --state="s3://"$CLUSTER_STATE_BUCKET


if [ "$DEPLOY_TYPE" = "update" ]; then
    echo "[$(date)] - This is an update, no need to create a new pki secret"
elif [ "$DEPLOY_TYPE" = "create" ]; then
    echo "[$(date)] - Creating pki secret and uploading to s3"
    kops create secret --name $CLUSTER_NAME sshpublickey admin -i ~/.ssh/k8s_id_rsa.pub --state="s3://"$CLUSTER_STATE_BUCKET
fi

echo "[$(date)] - Deploy the cluster"
kops update cluster $CLUSTER_NAME --yes \
    --state="s3://"$CLUSTER_STATE_BUCKET