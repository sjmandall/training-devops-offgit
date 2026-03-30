#!/bin/bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"

echo "Running smoke test against: $BASE_URL"

HOME_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/")
if [ "$HOME_CODE" != "200" ]; then
  echo "FAIL: Homepage returned HTTP $HOME_CODE"
  exit 1
fi

echo "PASS: Homepage returned 200"

INFO_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/info.php")
if [ "$INFO_CODE" != "200" ]; then
  echo "FAIL: info.php returned HTTP $INFO_CODE"
  exit 1
fi

echo "PASS: info.php returned 200"
echo "Smoke test passed"

