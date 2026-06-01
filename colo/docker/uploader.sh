#!/bin/bash

# Exit silently if no file argument provided
if [[ -z "$*" ]];
then
  exit 0
fi

FILEPATH="$*"
FILENAME=$(basename "$FILEPATH")

# Atomically claim the file by renaming it to .uploading so that multiple
# concurrent uploader workers or containers cannot process the same file twice.
# rename() is atomic on Linux — only one worker succeeds, others skip.
UPLOADING="${FILEPATH}.uploading"
if ! mv "${FILEPATH}" "${UPLOADING}" 2>/dev/null; then
  exit 0  # another worker already claimed this file
fi

UPLOAD_FILENAME=$(basename "${UPLOADING}" .uploading)

# S3_ACCESS_POINT is for the colo process to write to
FULL_S3_ACCESS_POINT_PATH=${S3_ACCESS_POINT}/${UPLOAD_FILENAME}

# S3_URL is for the cloud process to read from
FULL_S3_URL_PATH=${S3_URL}/${UPLOAD_FILENAME}

# Set S3 multipart threshold and chunksize via a shared AWS config file.
# These are config-file settings, not aws s3 cp CLI flags.
# Files from ports 8430-8437 average ~58MB. The default 8MB threshold splits
# each file into ~8 parts (~16s upload). Setting 64MB means files under 64MB
# use a single PUT (~1s upload) — 10x fewer S3 requests per file.
# The config file is created atomically (mktemp + mv -n) so concurrent xargs
# workers do not corrupt it by writing simultaneously.
AWS_CONFIG_FILE=/tmp/aws-uploader-config
export AWS_CONFIG_FILE
if [[ ! -f "${AWS_CONFIG_FILE}" ]]; then
  tmp_cfg="$(mktemp /tmp/aws-uploader-config.XXXXXX)"
  cat > "${tmp_cfg}" << 'EOF'
[default]
s3 =
  multipart_threshold = 67108864
  multipart_chunksize = 67108864
EOF
  mv -n "${tmp_cfg}" "${AWS_CONFIG_FILE}" 2>/dev/null || rm -f "${tmp_cfg}"
fi

# Upload to S3 and notify SQS with retry logic for transient failures.
for attempt in 1 2 3; do
  if aws s3 cp --quiet "${UPLOADING}" "${FULL_S3_ACCESS_POINT_PATH}"; then
    # Filename is used as both group-id and deduplication-id:
    # - group-id: ordering not required, allows unlimited parallel workers
    # - deduplication-id: prevents duplicate SQS messages on retry
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

# All 3 attempts failed — rename back to .zst so the next uploader cycle retries it
mv "${UPLOADING}" "${FILEPATH}"
echo "uploader: giving up after 3 attempts for ${UPLOADING}; renamed back for retry" >&2
exit 1
