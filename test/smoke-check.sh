#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "[SKIP] smoke-check is intended for non-root execution"
  exit 0
fi

set +e
output="$(bash ./dockerd-rootless-setuptool.sh check 2>&1)"
status=$?
set -e

echo "$output"

# Accept either success or an expected prerequisite failure, but reject crashes.
if [[ $status -eq 0 ]]; then
  if [[ "$output" != *"Requirements are satisfied"* ]]; then
    echo "[FAIL] check returned 0 without success message" >&2
    exit 1
  fi
  echo "[PASS] check succeeded with expected message"
  exit 0
fi

if [[ "$output" == *"Missing system requirements"* ]] || \
   [[ "$output" == *"needs to be present under $PATH"* ]] || \
   [[ "$output" == *"binary not found"* ]]; then
  echo "[PASS] check failed gracefully with actionable prerequisite message"
  exit 0
fi

echo "[FAIL] unexpected failure pattern from check (exit=$status)" >&2
exit 1
