# kubemanny

Multiple packages for managing your AWS EKS cluster, and deploying Kubeless functions

pronounced: [ku-be-manny](https://translate.google.com/#view=home&op=translate&sl=en&tl=en&text=ku-be-manny)

## Requirements

[Docker](https://docs.docker.com/install/) - that's it! Everything is included in the [kubemanny](https://hub.docker.com/r/unfor19/kubemanny) docker image!

<details><summary>Packages
</summary>
    
<table>
  <tr>
    <th>Package</th>
    <th>Version</th>
  </tr>
  <tr>
    <td>bash</td>
    <td>5.0.11</td>
  </tr>
  <tr>
    <td>git</td>
    <td>2.24.1</td>
  </tr>
  <tr>
    <td>kubeless</td>
    <td>1.0.6-dirty</td>
  </tr>
  <tr>
    <td>NodeJS</td>
    <td>12.16.1</td>
  </tr>
  <tr>
    <td>yarn</td>
    <td>1.22.0</td>
  </tr>
  <tr>
    <td>Python</td>
    <td>3.8.1</td>
  </tr>
  <tr>
    <td>pip</td>
    <td>20.0.2</td>
  </tr>
  <tr>
    <td>kubectl</td>
    <td>1.14.7-eks-1861c5</td>
  </tr>
  <tr>
    <td>eksctl</td>
    <td>GitTag: 0.13.0</td>
  </tr>
  <tr>
    <td>helm</td>
    <td>3.1.1</td>
  </tr>
  <tr>
    <td>terraform</td>
    <td>0.12.21</td>
  </tr>
  <tr>
    <td>aws-cli</td>
    <td>1.18.10</td>
  </tr>
  <tr>
    <td>chamber</td>
    <td>2.7.5</td>
  </tr>
  <tr>
    <td>apache2-utils</td>
    <td>2.4.27-r1</td>
  </tr>
</table>

</details>

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

**Tip**: Use [scripts/docker_run.sh](./scripts/docker_run.sh)

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
1. Build and Deploy your functions with [scripts/deploy_function.sh](./scripts/deploy_function.sh), this script does the following:
    - yarn install
    - yarn build:dev
    - Kubeless - delete function if exists
    - Kubeless - deploy function
    - Kubeless - create http trigger

## Quickstart (minikube)

Let's see if it really works, shall we?

<details><summary><b>Goal</b>
</summary>

I've created three functions: `greet_normal`, `greet_promise` and `greet_async`, see [src/controller.ts](./src/controller.ts)

In this example, we'll deploy `greet_promise`, a function which replies after 3 seconds with a random greeting message.

</details>

### Requirements

[VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/), that's it!

### minikube

Consider this as if you're starting a [Node](https://kubernetes.io/docs/concepts/architecture/nodes/)

```bash
kubemanny$: minikube start -p kubemanny-cluster --kubernetes-version v1.14.0 --vm-driver=virtualbox --memory 3072mb --disk-size 10240mb
...
⌛  Waiting for cluster to come online ...
🏄  Done! kubectl is now configured to use "kubemanny-cluster"
```

Install [nginx ingress controller](https://kubernetes.github.io/ingress-nginx/how-it-works/) to the cluster.

```bash
kubemanny$: minikube -p kubemanny-cluster addons enable ingress
✅  ingress was successfully enabled
```

**Note**: Even though it took 1 second to nginx-ingress-controller, it takes a few minutes until it's actually ready

<details><summary>Why do I need an ingress controller?
</summary>

An [ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) routes traffic from the outside world, to the releavnt [service](https://kubernetes.io/docs/concepts/services-networking/service/#service-resource) in the cluster.

The routing rules are defined with [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/#what-is-ingress) resources.

Each Kubeless function has an ingress rule, a service and a [deployment](<[deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#use-case)>).

You guessed it right, the deployment is our actual Kubeless function ([containerized](https://www.docker.com/resources/what-container)).

##### Process

1. The ingress controller routes traffic to the function according to its hostname (or [path > Expose a function](https://kubeless.io/docs/http-triggers/))
1. Kubeless function **ingress** rule contains the name of the service and its port
1. Kubeless function **service** contains the name of the targeted deployment

    </details>

<details><summary>Is there a dashboard or something like that?
</summary>

Yes there is!

```bash
kubemanny$: minikube -p kubemanny-cluster dashboard
```

**Tip**: The nginx-ingress-controller is deployed in the `kube-system` [namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

</details>

### kubemanny container

This is our workspace, with all the applications and packages that we need.

```bash
kubemanny$: bash ./scripts/docker_run_minikube.sh

/code (master)$      # <-- we're in!
```

<details><summary>Why do I need bind mounts?
</summary>

The container uses [bind mounts](https://docs.docker.com/storage/bind-mounts/), so each time you add/create/modify/delete a file within the container, or locally on your machine, it is mirrored both on the Docker container and your local machine.

In order for it to work, we are mounting the following directories:

1. `$HOME/.minikube` (readonly)
1. `$HOME/.kube/config` (readonly)
1. Current working directory (readwrite)

**Tip**: Take a look at the [scripts/docker_run_minikube.sh](./scripts/docker_run_minikube.sh) file

</details>

### Deploy Kubeless

Create a Kubeless namespace and create its deployment - [Source](https://kubeless.io/docs/quick-start/)

```bash
/code (master)$ kubectl create ns kubeless && kubectl create -f https://github.com/kubeless/kubeless/releases/download/v1.0.6/kubeless-v1.0.6.yaml
```

### basic-auth

It's always good practice to protect your functions, so let's use a simple basic-auth mechanism

1. Generate a secret with [htpasswd](https://httpd.apache.org/docs/2.4/programs/htpasswd.html)
1. Create a basic-auth [secret](https://kubernetes.io/docs/concepts/configuration/secret/)
1. Use the given credentials when sending a basic-auth request, see [scripts/curl_example.sh](./scripts/curl_example.sh)

```bash
/code (master)$ htpasswd -cb auth my_user_name my_password
Adding password for user my_user_name

/code (master)$ kubectl create secret generic basic-auth --from-file=auth
secret/basic-auth created
```

<details><summary>Can I view this secret?
</summary>

Yes you can! But you'll still need the username and password, when you request to invoke a Kubeless function.

```bash
/code (master)$ echo $(kubectl get secret basic-auth -o=jsonpath='{.data.auth}')
bXlfdXNlcl9uYW1lOiRhcHIxJG5BcjBUbEgvJE1USTBKUlhoaEhlN1R1dm4zSWlYRzEK   # <-- basic-auth secret
```

Let's decode it with base64, and let's view the auth file.

```bash
/code (master)$ echo $(kubectl get secret basic-auth -o=jsonpath='{.data.auth}' | base64 -d)
my_user_name:$apr1$ukcReKFZ$aE./88O0KMWZ2IsqL/xyk.   # <-- decoded

/code (master)$ cat auth
my_user_name:$apr1$ukcReKFZ$aE./88O0KMWZ2IsqL/xyk.   # <-- generated with htpasswd
```

Cool huh? Read more about it here - [htpasswd]

**Note**: The file `auth` is ignored in `.gitignore`

</details>

### Deploy Kubeless function

```bash
/code (master)$ bash ./scripts/deploy_function.sh -fn greet_promise -hn localhost
...
INFO[0000] Waiting for greet-promise to be ready ... Ready!
INFO[0000] View logs:
kubectl logs -f -l function=greet-promise
```

### Execute Kubeless function

The [scripts/curl_example.sh](./scripts/curl_example.sh) script gets the function's ingress, and then POSTs a basic auth request. Explore this file and play with it.

```bash
/code (master)$ bash ./scripts/curl_example.sh -fn greet-promise --name "meir"
INFO[0000] Function Name:     greet-promise
INFO[0000] Hostname:          greet-promise.192.168.99.105.nip.io
INFO[0000] Username:          my_user_name
INFO[0000] Password:          my_password
INFO[0000] Invoking a request ...
INFO[0000] Response:      Guten Targ meir
INFO[0000] Response time: 3.024527ms
```

**Tip**: Deploy the `greet-normal` function, and curl it. Watch for the response time!

### Cleanup

**IMPORTANT**: make sure you're not in the container, otherwise it won't work

Let's delete the minikube profile that we've created

```bash
/code (develop)$ exit
exit
kubemanny$: minikube delete -p kubemanny-cluster
🔥  Deleting "kubemanny-cluster" in virtualbox ...
💔  The "kubemanny-cluster" cluster has been deleted.
🔥  Successfully deleted profile "kubemanny-cluster"
```
