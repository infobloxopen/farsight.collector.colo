# Colo process
## Description
Colo is set up with a k3s installation. The colo process is then deployed with helm chart + docker image.

The colo process is a pod with 2 different types of containers:
- N Compressor containers: For N NMSG UDP port, there are N compressor that listen to them, compress the data and write to ramdisk location.
- Uploader container: responsible to upload the compressed nmsg files from ramdisk to S3 and register the file locations to SQS.

## Installation steps
### Specific to local dev
1. Create a local VM with Debian 9 (preferred, as Farsight set up colo with this flavor) or Ubuntu 18.04.

### Specific to colo
1. Ensure that [k3s.conf](./etc/ferm/conf.d/k3s.conf) exists in `/etc/ferm/conf.d/k3s.conf`. (This enables k3s components to talk to each others).
1. Run
```
systemctl reload ferm
```

### Common
1. Install dependencies
    ```
    bash colo/setup/install_dependencies.sh
    ```
1. On your own laptop, load helm chart and docker image into colo
    ```
    docker login
    docker pull infobloxcto/farsight-collector-colo:<version>
    docker save -o farsight-collector-colo-docker-image-<version>.tar infobloxcto/farsight-collector-colo:<version>
    scp farsight-collector-colo-docker-image-<version>.tar <colo-ip-address>

    aws s3 cp s3://infoblox-helm-dev/charts/farsight-collector-colo-<version>.tgz
    scp farsight-collector-colo-<version>.tgz <colo-ip-address>
    ```

1. On colo, prepare `values.yaml` from the example [values.yaml](./charts/farsight-collector-colo/values.yaml) and run:
    ```
    docker load -i farsight-collector-colo-docker-image-<version>.tar

    helm install farsight-collector-colo-<version>.tgz -f values.yaml -n colo-process
    ```

## Troubleshooting commands
### Soft clean up
```
helm delete --purge colo-process
```

### Hard clean up
```
k3s-killall.sh && docker stop $(docker ps -aq) && docker rm $(docker ps -aq)
```

### Ramdisk clean up
```
rm -rf /dev/shm/*
```

### Restart k3s:
```
systemcl restart k3s
```

## References
https://k3s.io/