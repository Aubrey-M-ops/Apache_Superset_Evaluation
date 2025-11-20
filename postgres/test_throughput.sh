#!/usr/bin/env bash
set -euo pipefail

# ---- set Postgres connection info ----
PGHOST=${PGHOST:-localhost}
PGPORT=${PGPORT:-5432}
PGUSER=${PGUSER:-postgres}
PGDATABASE=${PGDATABASE:-postgres}

# pgbench parameters
DURATION=${DURATION:-30}     # test duration in seconds
CLIENTS=${CLIENTS:-10}       # number of concurrent clients
THREADS=${THREADS:-4}        # number of worker threads

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

  name="${sql_file}"

  # ---------- 1. Run pgbench with custom SQL file ----------
  >&2 echo "Running pgbench for $sql_file..."

  pgbench_output=$(
    pgbench -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
      -c "$CLIENTS" -j "$THREADS" -T "$DURATION" \
      -f "$sql_file" -n 2>&1
  )

  # ---------- 2. Parse pgbench output ----------
  # Extract key metrics from pgbench output
  # Example output lines:
  # latency average = 15.234 ms
  # tps = 656.789012 (including connections establishing)
  # tps = 657.123456 (excluding connections establishing)

  latency_avg=$(echo "$pgbench_output" | grep "latency average" | awk '{print $4}')
  tps_excluding=$(echo "$pgbench_output" | grep "excluding connections" | awk '{print $3}')

  # If parsing fails, set defaults
  latency_avg=${latency_avg:-0}
  tps_excluding=${tps_excluding:-0}

  # ---------- 4. Calculate throughput (bytes/sec) ----------
  # throughput = tps * size_bytes
  throughput=$(awk -v tps="$tps_excluding" -v size="$size_bytes" \
    'BEGIN { printf "%.3f", tps * size }')

  # ---------- 5. output JSON ----------
  if [[ $first -eq 0 ]]; then
    echo ","
  fi
  first=0

  cat <<EOF
  "$name": {
    "latency_avg_ms": $latency_avg,
    "tps": $tps_excluding,
    "result_size_bytes": $size_bytes,
    "throughput_bytes_per_sec": $throughput
  }
EOF

done

echo "}"
