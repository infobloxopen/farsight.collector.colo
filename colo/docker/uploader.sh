#!/bin/bash

# if there is no file, wait then exit
if [[ -z "$*" ]];
then
  sleep 1
  exit 0
fi

FILEPATH="$*"
FILENAME=$(basename $FILEPATH)
FULL_S3_PATH=${S3_URL}/${FILENAME}

# Send to AWS
aws s3 cp ${FILEPATH} ${FULL_S3_PATH}
rm -f ${FILEPATH}

# Using filename as deduplication id to prevent duplicate messages
# Using filename as group id as ordering is not required,
# and to have unlimited number of workers without blocking
aws sqs send-message --queue-url ${SQS_URL} \
  --message-body ${FULL_S3_PATH} \
  --message-group-id ${FILENAME} \
  --message-deduplication-id ${FILENAME}
