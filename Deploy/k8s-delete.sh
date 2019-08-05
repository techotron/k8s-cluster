#!/usr/bin/env bash

AWS_PROFILE="snowco"
AWS_REGION="eu-west-1"
K8S_IAM_NAME="k8s-lab-iam"
CLUSTER_STATE_BUCKET="722777194664-k8s-clst-state-k8s-lab-env-eu-west-1"

export AWS_ACCESS_KEY_ID=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="AccessKeyId").OutputValue')
export AWS_SECRET_ACCESS_KEY=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="SecretAccessKey").OutputValue')

kops delete cluster --name lab.kube.esnow.uk --state="s3://"$CLUSTER_STATE_BUCKET --yes