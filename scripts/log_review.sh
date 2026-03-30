#!/bin/bash
set -e

ACCESS_LOG="/var/log/apache2/access.log"
ERROR_LOG="/var/log/apache2/error.log"
OUTFILE="$HOME/project/logs/apache-log-summary.txt"

mkdir -p "$(dirname "$OUTFILE")"

{
  echo "Apache Log Review Summary"
  echo "Generated: $(date)"
  echo

  echo "Last 20 Apache errors"
  if [ -f "$ERROR_LOG" ]; then
    tail -n 20 "$ERROR_LOG"
  else
    echo "Error log not found: $ERROR_LOG"
  fi

  echo
  echo "Top 10 client IPs from access log"
  if [ -f "$ACCESS_LOG" ]; then
    awk '{print $1}' "$ACCESS_LOG" | sort | uniq -c | sort -nr | head -10
  else
    echo "Access log not found: $ACCESS_LOG"
  fi
} > "$OUTFILE"

echo "Summary written to $OUTFILE"
