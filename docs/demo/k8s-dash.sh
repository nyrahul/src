#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml
kubectl apply -f k8s-dash-*.yaml
kubectl -n kubernetes-dashboard create token admin-user

