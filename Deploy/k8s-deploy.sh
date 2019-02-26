#!/usr/bin/env bash

if [ "$1" = "update" ]; then
    DEPLOY_TYPE="update"
elif [ "$1" = "create" ]; then
    DEPLOY_TYPE="create"
else
    DEPLOY_TYPE="create"
fi

AWS_PROFILE="intapp-devopssbx_eddy.snow@intapp.com"
AWS_REGION="eu-west-1"
K8S_IAM_NAME="eddy-k8s-iam"
K8S_STATE_NAME="eddy-k8s-state"
K8S_ENV_NAME="eddy-k8s-environment"
KOPS_CONFIG_VERSION=$(date +%F_%H%M%S)
S3_CONFIG_BUCKET="s3://278942993584-eddy-scratch/git/k8s-cluster/"
S3_CONFIG_BUCKET_US="s3://278942993584-eddy-scratch-us-east-1/git/k8s-cluster/"
S3_CONFIG_BUCKET_URL="https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/k8s-cluster/"
S3_CONFIG_BUCKET_URL_US="https://s3.amazonaws.com/278942993584-eddy-scratch-us-east-1/git/k8s-cluster/"


echo "[$(date)] - Deploying stacks to region: $AWS_REGION"
echo "[$(date)] - Uploading templates to s3"

aws s3 cp ../ $S3_CONFIG_BUCKET --recursive --profile $AWS_PROFILE --region $AWS_REGION --exclude "*.git/*"
aws s3 cp ../Infrastructure/CFN-ClusterStateStore.yaml $S3_CONFIG_BUCKET_US"Infrastructure/" --profile $AWS_PROFILE --region us-east-1

# Might need to create manually with a passphrase: ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s_id_rsa
echo "[$(date)] - Creating new PKI secret unless it already exists"
if [ ! -f ~/.ssh/k8s_id_rsa ]; then
    echo "[$(date)] - Secret not found, creating now"
    ssh-keygen -t rsa -N 'k8s_id_rsa' -f ~/.ssh/k8s_id_rsa
fi

echo "[$(date)] - iam stack"
if [ ! $(aws cloudformation describe-stacks --region $AWS_REGION --profile $AWS_PROFILE | jq '.Stacks[].StackName' | grep $K8S_IAM_NAME) ]; then
    echo "[$(date)] - Creating $K8S_IAM_NAME stack"
    aws cloudformation create-stack --stack-name $K8S_IAM_NAME --template-url $S3_CONFIG_BUCKET_URL"Infrastructure/CFN-kops.yaml" --parameters ParameterKey=AccessKeyRotation,ParameterValue=0 --profile $AWS_PROFILE --region $AWS_REGION --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM;
else
    echo "[$(date)] - Updating $K8S_IAM_NAME stack"
    aws cloudformation update-stack --stack-name $K8S_IAM_NAME --template-url $S3_CONFIG_BUCKET_URL"Infrastructure/CFN-kops.yaml" --parameters ParameterKey=AccessKeyRotation,ParameterValue=0 --profile $AWS_PROFILE --region $AWS_REGION --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM;
fi

echo "[$(date)] - cluster state store stack"
if [ ! $(aws cloudformation describe-stacks --region $AWS_REGION --profile $AWS_PROFILE | jq '.Stacks[].StackName' | grep $K8S_STATE_NAME) ]; then
    echo "[$(date)] - Creating $K8S_STATE_NAME stack"
    aws cloudformation create-stack --stack-name $K8S_STATE_NAME --template-url $S3_CONFIG_BUCKET_URL_US"Infrastructure/CFN-ClusterStateStore.yaml" --parameters ParameterKey=Environment,ParameterValue=dev --profile $AWS_PROFILE --region us-east-1;
else
    echo "[$(date)] - Updating $K8S_STATE_NAME stack"
    aws cloudformation update-stack --stack-name $K8S_STATE_NAME --template-url $S3_CONFIG_BUCKET_URL_US"Infrastructure/CFN-ClusterStateStore.yaml" --parameters ParameterKey=Environment,ParameterValue=dev --profile $AWS_PROFILE --region us-east-1;
fi

echo "[$(date)] - environment stack"
if [ ! $(aws cloudformation describe-stacks --region $AWS_REGION --profile $AWS_PROFILE | jq '.Stacks[].StackName' | grep $K8S_ENV_NAME) ]; then
    echo "[$(date)] - Creating $K8S_ENV_NAME stack"
    aws cloudformation create-stack --stack-name $K8S_ENV_NAME \
        --template-url $S3_CONFIG_BUCKET_URL"Infrastructure/CFN-Environment.yaml" \
        --parameters \
            ParameterKey=Network,ParameterValue="10.10" \
            ParameterKey=KubernetesDNS,ParameterValue="eu.sbx.kube.intapp.com" \
            ParameterKey=Environment,ParameterValue="dev" \
            ParameterKey=LoggerAccessKeyRotation,ParameterValue=0 \
            ParameterKey=contactTag,ParameterValue="eddy.snow@intapp.com" \
        --profile $AWS_PROFILE \
        --region $AWS_REGION \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM;
else
    echo "[$(date)] - Updating $K8S_ENV_NAME stack"
    aws cloudformation update-stack --stack-name $K8S_ENV_NAME \
        --template-url $S3_CONFIG_BUCKET_URL"Infrastructure/CFN-Environment.yaml" \
        --parameters \
            ParameterKey=Network,ParameterValue="10.10" \
            ParameterKey=KubernetesDNS,ParameterValue="eu.sbx.kube.intapp.com" \
            ParameterKey=Environment,ParameterValue="dev" \
            ParameterKey=LoggerAccessKeyRotation,ParameterValue=0 \
            ParameterKey=contactTag,ParameterValue="eddy.snow@intapp.com" \
        --profile $AWS_PROFILE \
        --region $AWS_REGION \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM;
fi

echo "[$(date)] - Exporting KOPS IAM credentials for KOPS related AWS tasks"
export AWS_ACCESS_KEY_ID=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="AccessKeyId").OutputValue')
export AWS_SECRET_ACCESS_KEY=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="SecretAccessKey").OutputValue')

echo "[$(date)] - Backing up old KOPS configuration"
aws s3 cp s3://k8s-clusterstatestorage-eddy-k8s-state-us-east-1/eddy.eu.sbx.kube.intapp.com s3://k8s-clusterstatestorage-eddy-k8s-state-us-east-1/$KOPS_CONFIG_VERSION/eddy.eu.sbx.kube.intapp.com --recursive --profile $AWS_PROFILE
aws s3 rm s3://k8s-clusterstatestorage-eddy-k8s-state-us-east-1/eddy.eu.sbx.kube.intapp.com --recursive --profile $AWS_PROFILE

echo "[$(date)] - Creating KOPS configuration and uploading to s3"
kops create -f ../Manifest/eu-eddy.sbx.kube.intapp.com.yaml --state="s3://k8s-clusterstatestorage-eddy-k8s-state-us-east-1"

if [ "$DEPLOY_TYPE" = "update" ]; then
    echo "[$(date)] - This is an update, no need to create a new pki secret"
elif [ "$DEPLOY_TYPE" = "create" ]; then
    echo "[$(date)] - Creating pki secret and uploading to s3"
    kops create secret --name eddy.eu.sbx.kube.intapp.com sshpublickey admin -i ~/.ssh/k8s_id_rsa.pub --state="s3://k8s-clusterstatestorage-eddy-k8s-state-us-east-1"
fi

echo "[$(date)] - Deploy the cluster"
kops update cluster eddy.eu.sbx.kube.intapp.com --yes --state="s3://k8s-clusterstatestorage-eddy-k8s-state-us-east-1"
