#!/usr/bin/env bash
set -euo pipefail

# sql files
FILES=(
  "scan.sql"
  "filter_scan.sql"
  "range_scan.sql"
  "update.sql"
  "aggregation.sql"
  "single_insert.sql"
)

echo "{"
first=1

for sql_file in "${FILES[@]}"; do
  if [[ ! -f "$sql_file" ]]; then
    >&2 echo "WARN: file '$sql_file' not found, skip"
    continue
  fi

  >&2 echo "Running pgbench for $sql_file..."

  # Run pgbench and capture output (only keep last 30 lines for parsing)
  pgbench_output=$(
    pgbench -h 127.0.0.1 -p 5432 -U postgres -d postgres \
      -c 50 -t 20 \
      -f "$sql_file" 2>&1 | tail -30
  )

  # Extract tps value (without initial connection time)
  tps=$(echo "$pgbench_output" | grep "tps = " | grep "without initial connection time" | awk '{print $3}')

  # If parsing fails, set default
  tps=${tps:-0}

  >&2 echo "tps: $tps"

  # Output JSON
  if [[ $first -eq 0 ]]; then
    echo ","
  fi
  first=0

  # Get filename without extension for key
  name="${sql_file%.sql}"

  cat <<EOF
  "$name": $tps
EOF

done

echo "}"
