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

  while true
  do
    # only process files ending with .zst; use find for robustness and null-safe handling
    file_count=$(find "${ZST_COMPLETE_DIR}" -maxdepth 1 -name '*.zst' -print0 | xargs -0 -n 1 -P ${UPLOADER_PARALLELISM} bash /bin/uploader.sh 2>/dev/null | wc -l)

    # if no files were found, sleep longer to reduce busy-looping
    if [[ $file_count -eq 0 ]]; then
      sleep 5
    fi
  done
fi
