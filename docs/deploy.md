# How to deploy and troubleshoot
## Deployment process
1. Assuming we want to work on process Channel 202, we'll have deployment name as `ch202-env2a`

1. Prepare `ch202-env2a-values.yaml` from the example [values.yaml](../colo/charts/farsight-collector-colo/values.yaml)

1. Prepare a `Secret` resource from `aws-credential` file (the file name must be exact). It should contain:
    ```
    [default]
    aws_access_key_id =
    aws_secret_access_key =
    ```

    Then run:
    ```
    kubectl create namespace ch202-env2a
    kubectl create secret generic aws-credential --from-file aws-credential -n ch202-env2a
    ```

    NOTE: please remember to delete the `aws-credential` after the Secret resource has been created.

1. (Optional, if not available) Add helm repo
    ```
    helm repo add infobloxopen https://raw.githubusercontent.com/infobloxopen/farsight.collector.colo/master/colo/charts
    ```

1. Run:
    ```
    helm repo update

    helm search infobloxopen/farsight-collector-colo

    helm install infobloxopen/farsight-collector-colo \
        --version <put-version-here> \
        --name ch202-env2a \
        --namespace ch202-env2a \
        -f ch202-env2a-values.yaml
    ```

## Troubleshooting commands
### Soft clean up
```
helm delete --purge colo-process
```

### Hard clean up
After running this command, please refer to [One-time setup](./setup.md) to recover.
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
