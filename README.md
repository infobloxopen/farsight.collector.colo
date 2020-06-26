# farsight.collector.colo
## Description
Colo is set up with a k3s installation. The colo process is then deployed with Helm chart + Docker image.

The colo process is a pod with 2 different types of containers:
- N Compressor containers: For N NMSG UDP port, there are N compressor that listen to them, compress the data and write to ramdisk location.
- Uploader container: responsible to upload the compressed nmsg files from ramdisk to S3 and register the file locations to SQS.

## Table of Contents

[How to release](./docs/release.md)

[How to do one-time setup](./docs/setup.md)

[How to deploy and do troubleshoot](./docs/deploy.md)
