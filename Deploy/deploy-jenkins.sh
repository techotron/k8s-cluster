#!/usr/bin/env bash

helm install --name jenkins-master  \
    --namespace ops \
    --tiller-namespace ops \
    ../Helm/jenkins