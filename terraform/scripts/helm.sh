#!/bin/sh

set -x

yc config set token ${YC_TOKEN} &&\
yc config set cloud-id b1gq442484mq45tns89c &&\
yc config set folder-id b1ggq6pgr3l3rc0t76s1

yc managed-kubernetes cluster get-credentials --id $(yc managed-kubernetes cluster list --format json | jq -r '.[].id') --external --force

kubectl cluster-info && kubectl get nodes

helm repo add examples https://helm.github.io/examples

kubectl get ns test || kubectl create ns test

helm upgrade --install ahoy --namespace test examples/hello-world --debug --atomic
