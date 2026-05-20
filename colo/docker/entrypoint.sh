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
  rm -v -f ${ZST_PARTIAL_DIR}/*${PREFIX}.nmsg.zst
  
  nmsgtool -l ${NMSG_SRC} -w ${NMSG_PARTIAL_DIR}/${PREFIX} -t ${COMPRESSOR_INTERVAL} -k /bin/compressor.sh
fi

if [[ "$POD_TYPE" == "UPLOADER" ]];
then
  echo "RUNNING $POD_TYPE $(date +%s)"
  mkdir -p ${ZST_COMPLETE_DIR}

  shopt -s nullglob
  while true
  do
    files=( "${ZST_COMPLETE_DIR}"/*.zst )

    # if no files were found, sleep longer to reduce busy-looping
    if [[ ${#files[@]} -eq 0 ]]; then
      sleep 5
      continue
    fi

    printf '%s\0' "${files[@]}" | xargs -0 -n 1 -P ${UPLOADER_PARALLELISM} bash /bin/uploader.sh
  done
fi
