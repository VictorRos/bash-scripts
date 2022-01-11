#!/bin/bash

files=($(ls bulletin*))

echo "Files: ${#files[@]}"

for filename in "${files[@]}"; do
  new_filename=$(echo "${filename}" |
    sed -E 's/bulletin/Bulletin/g' |
    sed -E 's/-/ /g' |
    sed -E 's/([0-9]{2})([0-9]{2})([0-9]{4})/\3-\2-\1/g')

  echo "Old filename: ${filename}"
  echo "New filename: ${new_filename}"

  mv "${filename}" "${new_filename}"
done
