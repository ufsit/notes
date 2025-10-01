echo $PATH | tr ':' '\n' | while read dir; do
  resolved=$(realpath "$dir" 2>/dev/null)
  if [ -n "$resolved" ] && [ -d "$resolved" ]; then
    ls -ld "$resolved"
  else
    echo "Invalid or non-existent path: $dir"
  fi
done