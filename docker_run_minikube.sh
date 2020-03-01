#!/bin/bash
kubeconfig_path=$(echo $HOME/.kube/config)
minikube_path=$(echo $HOME/.minikube)
docker run --rm -it \
        --mount type=bind,source="$(pwd)",target=/code \
        --mount type=bind,source="$minikube_path",target="$minikube_path",readonly \
        --mount type=bind,source="$kubeconfig_path",target=/root/.kube/config,readonly \
        unfor19/kubemanny:v1 \
        bash
