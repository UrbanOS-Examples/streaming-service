#!/usr/bin/env bash
set -e

delete-smoke-test-resources() {
    kubectl delete -f k8s/ \
        2>/dev/null \
        || echo "no smoke test deployments to delete"

    kubectl delete -f ../k8s/deployments \
        2>/dev/null \
        || echo "no kafka clusters to delete"

    while kubectl get pods | grep -q kafka; do
        echo "waiting for kafka cluster to delete"
        sleep 1
    done

    kubectl delete -f ../k8s/strimzi/cluster-operator \
        2>/dev/null \
        || echo "no strimzi operators to delete"
}

if ! minikube status; then
    minikube start --memory 8192
fi

kubectl config use-context minikube
eval $(minikube docker-env)

delete-smoke-test-resources
trap "delete-smoke-test-resources" EXIT

# manually change the k8s/01-deployment.yaml to `imagePullPolicy: Never` and to use this image
docker build -t 199837183662.dkr.ecr.us-east-2.amazonaws.com/scos/streaming-service-smoke-test:local .

kubectl apply -f ../k8s/strimzi/cluster-operator
kubectl apply -f ../k8s/deployments
kubectl apply -f k8s/

until kubectl logs -f kafka-smoke-tester 2>/dev/null; do
  echo "waiting for smoke test docker to start"
  sleep 1
done

kubectl --output=json get pod kafka-smoke-tester \
    | jq -r '.status.phase' \
    | grep -qx "Succeeded"
