#!/usr/bin/env bash

convert_flag=false

while getopts ":c" opt; do
  case $opt in
    c)
      convert_flag=true
      ;;
    \?)
      echo "Usage: $0 [-c]"
      exit
      ;;
  esac
done

detector() {
  local to_convert=()

  readarray -t list <<< $(find . -type f -name '*.mkv')
  IFS=','
  for i in "${list[@]}"; do
    mediaout=$(mediainfo $i | grep "HDR format")
    read -ra split <<< "$mediaout"
    for val in "${split[@]}"; do
      val=$(echo "$val" | xargs)
      if [ "$val" = "Profile 7.6" ]; then
        to_convert+=("$i")
        echo "[+] p7 detected: $i" >&2
        break
      fi
    done
  done
for path in "${to_convert[@]}"; do
  echo "$path"
done
}

convert() {
  local file=$1
  local dir=$(dirname "$file")

  echo "[*] Extracting HDR P7 track from \"$file\" to \"$dir/film_p7.hevc\""
  mkvextract tracks "$file" 0:"$dir/film_p7.hevc"

  echo "[*] Converting \"$dir/film_p7.hevc\" → \"$dir/film_p8.hevc\""
  dovi_tool -m 2 convert --discard "$dir/film_p7.hevc" -o "$dir/film_p8.hevc"

  echo "[*] Merging new P8 track into \"$file.p8\""
  mkvmerge -o "$file.p8" "$dir/film_p8.hevc" --no-video "$file"

  echo "[-] Removing temporary files: film_p7.hevc & film_p8.hevc"
  rm -f "$dir/film_p7.hevc" "$dir/film_p8.hevc"

  echo "[*] Replacing original with converted file"
  mv "$file.p8" "$file"

  echo "[+] Conversion complete for \"$file\""
}

readarray -t movies <<< $(detector)

if $convert_flag; then
  for mov in "${movies[@]}"; do
    (convert $mov)
  done
fi
