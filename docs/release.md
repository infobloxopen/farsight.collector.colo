# How to release
1. Release Helm chart
    1. Ensure `version` in [Chart.yaml](./colo/charts/farsight-collector-colo/Chart.yaml) is updated to the desired version. E.g `1.0.0` to `1.1.0`. This is **mandatory** step, as registry has immutable tags
    and CI will fail if tag was not changed.
    1. Run
        ```
        make chart
        ```
        This will generate artifacts and update related files.

    1. Commit the changes and raise PR to `master` branch. Once the PR is merged, proceed to next step.
