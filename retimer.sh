#!/bin/sh

OUTPUT_DIR="retimer-state"
OUTPUT_FILE="$OUTPUT_DIR/file_info.txt"

calculate_blake3() {
  b3sum "$1" --no-names
}

save_timestamps_and_hashes() {
  > "$OUTPUT_FILE"  # Clear existing file
  find . -name .git -prune -o -type f -print | while read -r file; do
    mtime=$(stat -c "%Y" "$file")
    hash=$(calculate_blake3 "$file")
    echo "$file $mtime $hash" >> "$OUTPUT_FILE"
  done
  cat "$OUTPUT_FILE"
}

restore_timestamps() {
  if [ -f "$OUTPUT_FILE" ]; then
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
  else
    echo "Output file $OUTPUT_FILE does not exist. Nothing to restore."
  fi
}

mkdir -p "$OUTPUT_DIR"
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
