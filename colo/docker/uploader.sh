#!/bin/bash

# if there is no file, exit silently
if [[ -z "$*" ]];
then
  exit 0
fi

FILEPATH="$*"
FILENAME=$(basename "$FILEPATH")

# Atomically claim the file by renaming it to .uploading
# mv/rename() is atomic on Linux — only one worker succeeds, others skip
UPLOADING="${FILEPATH}.uploading"
if ! mv "${FILEPATH}" "${UPLOADING}" 2>/dev/null; then
  exit 0  # another worker already claimed this file
fi

UPLOAD_FILENAME=$(basename "${UPLOADING}" .uploading)

# S3_ACCESS_POINT is to for colo process to write to
FULL_S3_ACCESS_POINT_PATH=${S3_ACCESS_POINT}/${UPLOAD_FILENAME}

# S3_URL is for cloud process to read from
FULL_S3_URL_PATH=${S3_URL}/${UPLOAD_FILENAME}

# Configure multipart threshold via AWS config.
# multipart_threshold/chunksize are config settings, not aws s3 cp CLI flags.
# Files average ~58MB; default 8MB threshold = ~8 parts per file (~16s upload).
# 64MB threshold = single PUT for <64MB files (~1s upload), 10x fewer S3 requests.
export AWS_CONFIG_FILE=/tmp/aws-uploader-config
aws configure set s3.multipart_threshold 67108864
aws configure set s3.multipart_chunksize 67108864

# Send to AWS with retry logic for transient failures.
for attempt in 1 2 3; do
  if aws s3 cp --quiet "${UPLOADING}" "${FULL_S3_ACCESS_POINT_PATH}"; then
    # Using filename as deduplication id to prevent duplicate messages
    # Using filename as group id as ordering is not required,
    # and to have unlimited number of workers without blocking
    if aws sqs send-message --queue-url "${SQS_URL}" \
      --message-body "${FULL_S3_URL_PATH}" \
      --message-group-id "${UPLOAD_FILENAME}" \
      --message-deduplication-id "${UPLOAD_FILENAME}" \
      > /dev/null; then
      rm -f "${UPLOADING}"
      exit 0
    else
      echo "uploader: attempt ${attempt}/3 failed sending SQS message for ${UPLOADING}" >&2
    fi
  else
    echo "uploader: attempt ${attempt}/3 failed uploading to S3 for ${UPLOADING}" >&2
  fi

  if [[ ${attempt} -lt 3 ]]; then
    sleep $((attempt * 2))
  fi
done

# Upload failed — rename back to .zst so it gets retried next cycle
mv "${UPLOADING}" "${FILEPATH}"
echo "uploader: giving up after 3 attempts for ${UPLOADING}; renamed back for retry" >&2
exit 1
