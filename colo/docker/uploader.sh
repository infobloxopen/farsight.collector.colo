#!/bin/bash

# if there is no file, exit silently
if [[ -z "$*" ]];
then
  exit 0
fi

FILEPATH="$*"
FILENAME=$(basename "$FILEPATH")

# S3_ACCESS_POINT is to for colo process to write to
FULL_S3_ACCESS_POINT_PATH=${S3_ACCESS_POINT}/${FILENAME}

# S3_URL is for cloud process to read from
FULL_S3_URL_PATH=${S3_URL}/${FILENAME}

# Send to AWS with retry logic for transient failures
for attempt in {1..3}; do
  if aws s3 cp --quiet "${FILEPATH}" "${FULL_S3_ACCESS_POINT_PATH}"; then
    break
  fi
  if [[ $attempt -lt 3 ]]; then
    sleep $((attempt * 2))
  fi
done

# If S3 upload failed, leave file on ramdisk for retry; don't exit 1 to keep xargs alive
if [[ ! -e "${FILEPATH}" ]]; then
  # Using filename as deduplication id to prevent duplicate messages
  # Using filename as group id as ordering is not required,
  # and to have unlimited number of workers without blocking
  aws sqs send-message --queue-url ${SQS_URL} \
    --message-body "${FULL_S3_URL_PATH}" \
    --message-group-id "${FILENAME}" \
    --message-deduplication-id "${FILENAME}" \
    > /dev/null 2>&1
fi
