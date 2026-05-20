#!/bin/bash

if [ -s "$1" ]
then
  # The original filename is 127-0-0-1-8430.20200611.1958.1591905534.162597591.nmsg
  # We need to swap the time part to the front so that 'ls' can return sorted by time during uploading time
  OLD_FILENAME=$(basename "$1")
  IFS='.' read -r field1 field2 field3 field4 field5 _ <<< "$OLD_FILENAME"
  NEW_FILENAME="${field2}.${field3}.${field4}.${field5}.${field1}.nmsg.zst"

  # Compress the file; on failure, clean up the partial output but keep the source
  if ! zstd --rm -q -z "$1" -o "${ZST_PARTIAL_DIR}/${NEW_FILENAME}"; then
    rm -f "${ZST_PARTIAL_DIR}/${NEW_FILENAME}"
    exit 1
  fi

  # Move it to the upload queue when it is ready
  mv "${ZST_PARTIAL_DIR}/${NEW_FILENAME}" "${ZST_COMPLETE_DIR}/${NEW_FILENAME}"
else
  rm -f "$1"
fi