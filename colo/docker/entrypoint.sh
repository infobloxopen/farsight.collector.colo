#!/bin/bash

if [[ "$POD_TYPE" == "COMPRESSOR" ]];
then
  echo "RUNNING $POD_TYPE `date +%s`"
  mkdir -p ${NMSG_PARTIAL_DIR}
  mkdir -p ${ZST_PARTIAL_DIR}
  mkdir -p ${ZST_COMPLETE_DIR}

  PREFIX=$(echo $NMSG_SRC | sed "s/[\.|\/]/-/g")
  nmsgtool -l ${NMSG_SRC} -w ${NMSG_PARTIAL_DIR}/${PREFIX} -t ${COMPRESSOR_INTERVAL} -k /bin/compressor.sh
fi

if [[ "$POD_TYPE" == "UPLOADER" ]];
then
  echo "RUNNING $POD_TYPE `date +%s`"
  mkdir -p ${ZST_COMPLETE_DIR}

  while true
  do
    # only list files end with zst
    # if there is no file, output to /dev/null
    ls ${ZST_COMPLETE_DIR}/*zst 2> /dev/null | xargs -n 1 -P ${UPLOADER_PARALLELISM} bash /bin/uploader.sh

    # short time to wait for more files
    sleep 1
  done
fi
