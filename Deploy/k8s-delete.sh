#!/usr/bin/env bash

AWS_PROFILE="intapp-devopssbx_eddy.snow@intapp.com"
AWS_REGION="eu-west-1"
K8S_IAM_NAME="eddy-k8s-iam"

export AWS_ACCESS_KEY_ID=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="AccessKeyId").OutputValue')
export AWS_SECRET_ACCESS_KEY=$(aws cloudformation describe-stacks --stack-name $K8S_IAM_NAME --region $AWS_REGION --profile $AWS_PROFILE | jq --raw-output '.Stacks[].Outputs[] | select(.OutputKey=="SecretAccessKey").OutputValue')

kops delete cluster --name eddy.eu.sbx.kube.intapp.com --state="s3://k8s-clusterstatestorage-eddy-k8s-environment-eu-west-1" --yes