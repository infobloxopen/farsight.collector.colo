#!/bin/bash

if [[ "$POD_TYPE" == "COMPRESSOR" ]];
then
  echo "RUNNING $POD_TYPE $(date +%s)"
  mkdir -p ${NMSG_PARTIAL_DIR}
  mkdir -p ${ZST_PARTIAL_DIR}
  mkdir -p ${ZST_COMPLETE_DIR}

  PREFIX=$(echo $NMSG_SRC | sed "s/[\.|\/]/-/g")
  
  echo "CLEANING UP OLD PARTIAL NMESG FILES"
  rm -v -f ${NMSG_PARTIAL_DIR}/${PREFIX}*.nmsg
  rm -v -f ${NMSG_PARTIAL_DIR}/.${PREFIX}*.part
  
  echo "CLEANING UP OLD PARTIAL ZSTD FILES"
  rm -v -f ${ZST_PARTIAL_DIR}/*.${PREFIX}.nmsg.zst

  nmsgtool -l ${NMSG_SRC} -w ${NMSG_PARTIAL_DIR}/${PREFIX} -t ${COMPRESSOR_INTERVAL} -k /bin/compressor.sh
fi

if [[ "$POD_TYPE" == "UPLOADER" ]];
then
  echo "RUNNING $POD_TYPE $(date +%s)"
  mkdir -p ${ZST_COMPLETE_DIR}

  # On startup, rename any orphaned .uploading files back to .zst
  # These are left behind when an uploader container crashed mid-upload
  echo "CLEANING UP ORPHANED .uploading FILES"
  for f in "${ZST_COMPLETE_DIR}"/*.uploading; do
    [ -f "$f" ] && mv "$f" "${f%.uploading}" && echo "recovered: $f" >&2
  done

  shopt -s nullglob
  while true
  do
    files=( "${ZST_COMPLETE_DIR}"/*.zst )

    # if no files were found, sleep longer to reduce busy-looping
    if [[ ${#files[@]} -eq 0 ]]; then
      sleep 5
      continue
    fi

    # Log backlog size so we can spot accumulation early
    if [[ ${#files[@]} -gt 50 ]]; then
      echo "uploader: WARNING: backlog is ${#files[@]} files in ${ZST_COMPLETE_DIR}" >&2
    fi

    # Process at most 200 files per cycle so newly-arrived files are not starved.
    # Atomic rename in uploader.sh means multiple uploader containers can safely
    # run concurrently without file contention.
    printf '%s\0' "${files[@]:0:200}" | xargs -0 -n 1 -P ${UPLOADER_PARALLELISM} bash /bin/uploader.sh
  done
fi
