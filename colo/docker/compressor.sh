#!/bin/bash

if [ -s $1 ]
then
  # The original filename is 127-0-0-1-8430.20200611.1958.1591905534.162597591.nmsg
  # We need to swap the time part to the front so that 'ls' can return sorted by time during uploading time
  NEW_FILENAME=$(basename $1|awk -F'.' '{print $2"."$3"."$4"."$5"."$1".nmsg.zst"}')

  # Compress the file
  zstd --rm -q -z $1 -o ${ZST_PARTIAL_DIR}/${NEW_FILENAME}

  # Move it to the upload queue when it is ready
  mv ${ZST_PARTIAL_DIR}/${NEW_FILENAME} ${ZST_COMPLETE_DIR}/${NEW_FILENAME}
else
  rm -f $1
fi