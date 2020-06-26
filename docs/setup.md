# One-time setup
## Specific to local dev
1. Create a local VM with Debian 9 (preferred, as Farsight set up colo with this flavor) or Ubuntu 18.04.

## Specific to colo
1. Ensure that [k3s.conf](./setup/etc/ferm/conf.d/k3s.conf) exists in `/etc/ferm/conf.d/k3s.conf`. (This enables k3s components to talk to each others).
1. Run
```
systemctl reload ferm
```

## Common
1. Install software dependencies
    ```
    #!/bin/bash

    # install docker
    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    sudo apt-get update -y
    sudo apt-get install -y docker-ce


    # install k3s
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik --docker" INSTALL_K3S_VERSION="v1.18.3+k3s1" sh -
    echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
    source ~/.bashrc
    sleep 30


    # install helm
    curl -L https://git.io/get_helm.sh | DESIRED_VERSION=v2.16.7 bash
    kubectl -n kube-system create serviceaccount tiller
    kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
    helm init --service-account tiller --history-max 200
    sleep 30
    ```

1. Add Helm repo
    ```
    helm repo add infobloxopen https://raw.githubusercontent.com/infobloxopen/farsight.collector.colo/master/colo/charts
    helm update
    ```