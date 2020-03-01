# kubemanny

Multiple packages for managing your AWS EKS cluster, and deploying Kubeless functions

pronounced: [ku-be-manny](https://translate.google.com/#view=home&op=translate&sl=en&tl=en&text=ku-be-manny)

## Requirements

[Docker](https://docs.docker.com/install/) - that's it! Everything is included in the [kubemanny](https://hub.docker.com/r/unfor19/kubemanny) docker image!

## Usage

Two common ways to use this image

-   AWS Credentials as env vars

    ```bash
    kubeconfig_path=$(echo ~/.kube/config)
    docker run --rm -it \
             --mount type=bind,source="$(pwd)",target=/code \
             --mount type=bind,source="$kubeconfig_path",target=/root/.kube/config,readonly \
             --env AWS_REGION="${AWS_REGION}" \
             --env AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
             --env AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
             unfor19/kubemanny:v1 \
             bash
    ```

-   aws-vault
    ```bash
     kubeconfig_path=$(echo ~/.kube/config)
     aws-vault exec MY_PROFILE -- docker run --rm -it \
              --mount type=bind,source="$(pwd)",target=/code \
              --mount type=bind,source="$kubeconfig_path",target=/root/.kube/config,readonly \
              --env AWS_REGION="${AWS_REGION}" \
              --env AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
              --env AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
              --env AWS_SECURITY_TOKEN="${AWS_SECURITY_TOKEN}" \
              --env AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN}" \
              unfor19/kubemanny:v1 \
              bash
    ```

## Getting Started with Kubeless

1. Install an [Ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) on your cluster, see [Kubeless http triggers](https://kubeless.io/docs/http-triggers/)
1. Clone this repository
1. Write your code in [src](./src)
1. Expose your functions in [src/main.ts](./src/main.ts)
1. Run container with [docker_run.sh](./docker_run.sh)
1. Install dependencies, see [package.json](./package.json)
    ```bash
    kubemanny$: yarn install
    ```
1. Build and Deploy your functions with [deploy_function.sh](./deploy_function.sh), this script does the following:
    - yarn build:dev
    - Delete function if exists
    - Kubeless - deploy function
    - Kubeless - create http trigger

## Quickstart (minikube)

Let's see if it really works, shall we?

I've created three functions: `greet_normal`, `greet_promise` and `greet_async`, see [src/controller.ts](./src/controller.ts)

In this example, we'll deploy `greet_promise`, a function which replies after 3 seconds with a random greeting message.

### Requirements

[VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/), that's it!

### Start minikube

Start minikube

```bash
kubemanny$: minikube start --kubernetes-version v1.14.0 --vm-driver=virtualbox
...
🏄  Done! kubectl is now configured to use "minikube"


kubemanny$: kubectl config use-context minikube  # just to make sure we're using minikube
Switched to context "minikube".
```

Enable nginx controller

```bash
kubemanny$: addons enable ingress       # to expose Kubeless functions
✅  ingress was successfully enabled
```

### Start kubemanny container

[Bind mounts](https://docs.docker.com/storage/bind-mounts/)

1. `$HOME/.minikube` (readonly)
1. `$HOME/.kube/config` (readonly)
1. Current working directory (readwrite)

```bash
kubemanny$: bash ./docker_run_minikube.sh

/code (master)$
```

### Deploy Kubeless

Create the Kubeless namespace and create its deployment - [Source](https://kubeless.io/docs/quick-start/)

```bash
/code (master)$ kubectl create ns kubeless && kubectl create -f https://github.com/kubeless/kubeless/releases/download/v1.0.6/kubeless-v1.0.6.yaml
```

### basic-auth

It's always good practice to protect your functions, so let's use a simple basic-auth mechanism

1. Create a basic-auth secret
1. Copy the secret

```bash
/code (master)$ htpasswd -cb auth my_user_name my_password
Adding password for user my_user_name

/code (master)$ kubectl create secret generic basic-auth --from-file=auth
secret/basic-auth created

/code (master)$ echo $(kubectl get secret basic-auth -o=jsonpath='{.data.auth}')

bXlfdXNlcl9uYW1lOiRhcHIxJG9sYThnenh3JDJrc0kyZEc0RS9PWTB6L2ZzTVFENTAK   # <-- basic-auth secret
```

**Note**: The file `auth` is ignored in `.gitignore`

### Deploy Kubeless function

```bash
/code (master)$ bash deploy_function.sh -fn greet_promise -hn localhost
...
INFO[0000] Waiting for greet-promise to be ready ... Ready!
INFO[0000] View logs:
kubectl logs -f -l function=greet-promise
```

### Execute Kubeless function

The [curl_example.sh](./curl_example.sh) script gets the function's ingress, and then POSTs a basic auth request. Explore this file and play with it.

```bash
/code (master)$ bash curl_example.sh
Alrighty then! meir
/code (master)$ bash curl_example.sh
Howdy meir
/code (master)$ bash curl_example.sh
Howyadoin'? meir
```

### Cleanup

**IMPORTANT**: make sure you're not in the container, otherwise it won't work

```bash
kubemanny$: minikube delete
```
