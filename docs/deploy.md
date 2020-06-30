# How to deploy and troubleshoot
## Deployment process
1. Assuming we want to work on process Channel 202, we'll have deployment name as `colo-ch202`

1. Prepare `values.yaml` from the example [values.yaml](./charts/farsight-collector-colo/values.yaml)

1. Prepare a `Secret` resource from `aws-credential` file (the file name must be exact). It should contain:
    ```
    [default]
    aws_access_key_id =
    aws_secret_access_key =
    ```

    Then run:
    ```
    kubectl create secret generic aws-credential --from-file aws-credential -n colo-ch202
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
        --name colo-ch202 \
        --namespace colo-ch202 \
        -f values.yaml
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
