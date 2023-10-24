#!/bin/sh

OUTPUT_FILE="retimer-state/file_info.txt"

calculate_blake3() {
  b3sum "$1" | awk '{print $1}'
}

save_timestamps_and_hashes() {
  echo "Saving timestamps"
  pwd
  > "$OUTPUT_FILE"  # Clear existing file
  find . -type f | while read -r file; do
    mtime=$(stat -c "%Y" "$file")
    hash=$(calculate_blake3 "$file")
    echo "$file $mtime $hash" >> "$OUTPUT_FILE"
  done
  tail "$OUTPUT_FILE"
}

restore_timestamps() {
  echo "Restoring timestamps"
  pwd
  while read -r line; do
    echo "$line"
    file=$(echo "$line" | awk '{print $1}')
    mtime=$(echo "$line" | awk '{print $2}')
    hash=$(echo "$line" | awk '{print $3}')
    
    if [ "$(calculate_blake3 "$file")" = "$hash" ]; then
      echo "Restoring mtime for $file"
      touch -d "@$mtime" "$file"
    else
      echo "Hash mismatch for $file"
    fi
  done < "$OUTPUT_FILE"
}

case "$1" in
  "save")
    save_timestamps_and_hashes
    ;;
  "restore")
    restore_timestamps
    ;;
  *)
    echo "Usage: $0 {save|restore}"
    exit 1
    ;;
esac
