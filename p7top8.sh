#!/usr/bin/env bash

convert_flag=false
while getopts ":c" opt; do
  case $opt in
    c) convert_flag=true ;;
    \?) echo "Usage: $0 [-c]" >&2; exit 1 ;;
  esac
done

detector() {
  local to_convert=()
  while IFS= read -r -d '' file; do
    if mediainfo --Inform="Video;%HDR_Format_String%" "$file" | grep -q "Profile 7\.6"; then
      to_convert+=("$file")
      echo "[+] p7 detected: $file" >&2
    fi
  done < <(find . -type f -name '*.mkv' -print0)

  printf '%s\0' "${to_convert[@]}"
}

convert() {
  local file=$1
  local dir
  dir=$(dirname "$file")
  local track_id

  track_id=$(
    mkvmerge -i "$file" |
    awk -F':' '/video/ {
      sub(/.*Track ID /, "", $1)
      print $1
      exit
    }'
  )

  echo "[*] Extracting HDR P7 track from \"$file\""
  mkvextract tracks "$file" "${track_id}":"$dir/film_p7.hevc"

  echo "[*] Converting p7 track to p8"
  dovi_tool -m 2 convert --discard "$dir/film_p7.hevc" -o "$dir/film_p8.hevc"

  echo "[*] Merging P8 track"
  mkvmerge -o "$file.p8" "$dir/film_p8.hevc" --no-video "$file"

  echo "[-] Cleaning"
  rm -f "$dir/film_p7.hevc" "$dir/film_p8.hevc"
  mv "$file.p8" "$file"

  echo "[+] Conversion complete for \"$file\""
}

mapfile -d '' movies < <(detector)

if $convert_flag; then
  for mov in "${movies[@]}"; do
    convert "$mov"
  done
fi
