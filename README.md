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

No need for anything! We'll use [Hello-Minikube](https://kubernetes.io/docs/tutorials/hello-minikube/#create-a-minikube-cluster), so all you need is a browser :yum:

<details><summary>To run locally
</summary>

1. [Docker](https://docs.docker.com/install/)
1. [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
1. [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
1. Clone this repository

```bash
kubemanny$ minikube start -p kubemanny-cluster --kubernetes-version v1.14.0 --vm-driver=virtualbox --memory 3072mb --disk-size 10240mb

kubemanny$ minikube addons enable ingress -p kubemanny-cluster
```

</details>

### minikube

Consider this as if you're starting a [Cluster](https://kubernetes.io/docs/reference/glossary/?all=true#term-cluster) with one worker node [Node](https://kubernetes.io/docs/concepts/architecture/nodes/)

1. :walking: Go to [Hello-Minikube](https://kubernetes.io/docs/tutorials/hello-minikube/)
1. :punch: Hit Launch Terminal
1. :hourglass_flowing_sand: Wait for environment (~3 min)
1. :computer: Recreate a new minikube machine with kubernetes v1.14 ([here's why](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html))
    ```bash
    $ minikube delete && minikube start --kubernetes-version v1.14.0
    * Uninstalling Kubernetes v1.17.0 using kubeadm ...
    ...
    * Successfully deleted profile "minikube"
    ...
    * Launching Kubernetes ...
    * Configuring local host environment ...
    * Waiting for cluster to come online ...
    * Done! kubectl is now configured to use "minikube"
    ! /usr/bin/kubectl is version 1.17.0, and is incompatible with Kubernetes 1.14.0. You will need to update /usr/bin/kubectl or use 'minikube kubectl' to connect with this cluster
    ```
    **Note**: We don't care about this message :point_up: because the kubemanny image has kubectl-v1.14
1. :arrows_clockwise: Install [nginx ingress controller](https://kubernetes.github.io/ingress-nginx/how-it-works/) to the cluster
    ```bash
    $ minikube addons enable ingress
    * ingress was successfully enabled
    ```
    **Note**: Even though it took 1 second to deploy the nginx-ingress-controller, it takes a few minutes until it's actually ready

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
$ minikube dashboard
```

**Tip**: The nginx-ingress-controller is deployed in the `kube-system` [namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

</details>

### kubemanny container

This is our workspace, with all the applications and packages that we need.

1. :arrow_down: Clone this repository, and get in!
    ```bash
    $ git clone https://github.com/unfor19/kubemanny.git
    ...
    Unpacking objects: 100% (57/57), done.
    $ cd kubemanny/
    ```
1. :whale2: Run the container

    ```bash
    $ bash ./scripts/docker_run_minikube.sh
    Unable to find image 'unfor19/kubemanny:v1' locally
    ...
    Status: Downloaded newer image for unfor19/kubemanny:v1
    /code (master)$      # <-- we're in!!!
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

Kubeless allows us to deploy our functions to the Kubernetes cluster. In order to have this ability, we first need to deploy Kubeless to our cluster.

1. :arrows_clockwise: Create a namespace for Kubeless
    ```bash
    /code (master)$ kubectl create ns kubeless
    namespace/kubeless created
    ```
1. :arrows_clockwise: Create the Kubeless deployment
    ```bash
    /code (master)$ kubectl create -f https://github.com/kubeless/kubeless/releases/download/v1.0.6/kubeless-v1.0.6.yaml
    configmap/kubeless-config created
    ...
    customresourcedefinition.apiextensions.k8s.io/cronjobtriggers.kubeless.io created
    ```

[Source](https://kubeless.io/docs/quick-start/)

### basic-auth

It's always good practice to protect your functions, so let's use a simple basic-auth mechanism

1. :u5272: Generate a secret with [htpasswd](https://httpd.apache.org/docs/2.4/programs/htpasswd.html)
    ```bash
    /code (master)$ htpasswd -cb auth my_user_name my_password
    Adding password for user my_user_name
    ```
1. :arrows_clockwise: Create a basic-auth [secret](https://kubernetes.io/docs/concepts/configuration/secret/)
    ```bash
    /code (master)$ kubectl create secret generic basic-auth --from-file=auth
    secret/basic-auth created
    ```

**Note**: Will use the above credentials when sending a basic-auth request, see [scripts/curl_example.sh](./scripts/curl_example.sh)

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

Cool huh? Read more about it here - [htpasswd](https://httpd.apache.org/docs/2.4/programs/htpasswd.html)

**Note**: The file `auth` is ignored in `.gitignore`

</details>

### Deploy Kubeless function

:metal: Now for the fun part! Let's deploy the `greet_promise` function

```bash
/code (master)$ bash ./scripts/deploy_function.sh -fn greet_promise -hn localhost
yarn install v1.22.0
...
INFO[0000] Waiting for greet-promise to be ready ... Ready!
INFO[0000] View logs:
kubectl logs -f -l function=greet-promise
```

### Execute Kubeless function

:crossed_fingers: The [scripts/curl_example.sh](./scripts/curl_example.sh) script gets the function's ingress, and then POSTs a basic auth request. Run with `--help` flag to see available options.

```bash
/code (master)$ bash ./scripts/curl_example.sh -fn greet-promise --name meir
INFO[0000] Function Name:     greet-promise
INFO[0000] Hostname:          greet-promise.172.17.0.56.nip.io
INFO[0000] Username:          my_user_name
INFO[0000] Password:          my_password
INFO[0000] Invoking a request ...
INFO[0000] Response:      Guten Targ meir
INFO[0000] Response time: 3.024527ms
```

**Tip**: Deploy the `greet-normal` function, and curl it. Watch for the response time!

### Cleanup

Close the browser tab :sunglasses:

<details><summary>Locally
</summary>

**IMPORTANT**: make sure you're not in the container, otherwise it won't work

Let's delete the minikube profile that we've created

```bash
/code (master)$ exit
exit
kubemanny$: minikube delete -p kubemanny-cluster
🔥  Deleting "kubemanny-cluster" in virtualbox ...
💔  The "kubemanny-cluster" cluster has been deleted.
🔥  Successfully deleted profile "kubemanny-cluster"
```

</details>
