#!/bin/bash

# if there is no file, wait then exit
if [[ -z "$*" ]];
then
  sleep 1
  exit 0
fi

FILEPATH="$*"
FILENAME=$(basename $FILEPATH)

# S3_ACCESS_POINT is to for colo process to write to
FULL_S3_ACCESS_POINT_PATH=${S3_ACCESS_POINT}/${FILENAME}

# S3_URL is for cloud process to read from
FULL_S3_URL_PATH=${S3_URL}/${FILENAME}

# Send to AWS
aws s3 cp ${FILEPATH} ${FULL_S3_ACCESS_POINT_PATH}
rm -f ${FILEPATH}

# Using filename as deduplication id to prevent duplicate messages
# Using filename as group id as ordering is not required,
# and to have unlimited number of workers without blocking
aws sqs send-message --queue-url ${SQS_URL} \
  --message-body ${FULL_S3_URL_PATH} \
  --message-group-id ${FILENAME} \
  --message-deduplication-id ${FILENAME}
