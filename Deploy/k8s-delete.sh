#!/usr/bin/env bash

AWS_PROFILE="snowco"
AWS_REGION="eu-west-2"
NAME="lab"
K8S_STACK_NAME="k8s-lab"
K8S_DNS_DOMAIN="kube.esnow.uk"
K8S_IAM_NAME="$K8S_STACK_NAME-iam"
K8S_ENV_NAME="$K8S_STACK_NAME-env"
CLUSTER_NAME="$NAME.$K8S_DNS_DOMAIN"
K8S_NETWORK="10.10"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text --profile $AWS_PROFILE)
CLUSTER_STATE_BUCKET="$AWS_ACCOUNT_ID-k8s-clst-state-$K8S_ENV_NAME-$AWS_REGION"

export AWS_ACCESS_KEY_ID=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="AccessKeyId").OutputValue')
export AWS_SECRET_ACCESS_KEY=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="SecretAccessKey").OutputValue')

kops delete cluster --name $CLUSTER_NAME --state="s3://"$CLUSTER_STATE_BUCKET --yes