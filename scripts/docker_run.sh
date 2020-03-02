#!/bin/bash
kubeconfig_path=$(echo ~/.kube/config)
if [[ ! -z ${AWS_SECURITY_TOKEN} && ! -z ${AWS_SESSION_TOKEN} ]]; then
        docker run --rm -it \
                --mount type=bind,source="${PWD}",target=/code \
                --mount type=bind,source="$kubeconfig_path",target=/root/.kube/config,readonly \
                --env AWS_REGION="${AWS_REGION}" \
                --env AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
                --env AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
                --env AWS_SECURITY_TOKEN="${AWS_SECURITY_TOKEN}" \
                --env AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN}" \
                unfor19/kubemanny:v1 \
                bash
else
        docker run --rm -it \
                --mount type=bind,source="${PWD}",target=/code \
                --mount type=bind,source="$kubeconfig_path",target=/root/.kube/config,readonly \
                --env AWS_REGION="${AWS_REGION}" \
                --env AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
                --env AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
                unfor19/kubemanny:v1 \
                bash
fi


