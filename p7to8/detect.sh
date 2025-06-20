#!/bin/usr/env bash

# Detects Profile 7.6 Movies

readarray -t list <<< $(find . -type f -name '*.mkv')

IFS=','
for i in "${list[@]}"; do
  mediaout=$(mediainfo $i | grep "HDR format")
  read -ra split <<< "$mediaout"

  for val in "${split[@]}"; do
    val=$(echo "$val" | xargs)
    if [ "$val" = "Profile 7.6" ]; then
      echo "$i"
    fi
      continue
  done
done
