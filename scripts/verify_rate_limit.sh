#!/bin/bash
set -e

BASE_URL=${1:-"http://localhost:4000/api/tournaments"}
LIMIT=70

echo "Starting rate limit verification..."
echo "Sending $LIMIT requests to $BASE_URL..."

for ((i=1; i<=LIMIT; i++)); do
  # Use curl to fetch headers only (-I) and inspect the HTTP status code.
  # We use -s to silence progress meter.
  # -o /dev/null to discard output.
  # -w "%{http_code}" to print the status code.
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -I "$BASE_URL")
  
  if [ "$STATUS" == "429" ]; then
    echo "Request $i: $STATUS (Rate Limit Exceeded)"
  else
    echo "Request $i: $STATUS"
  fi
  
  # Optional: slight delay if needed, but we want to hit the limit quickly.
  # sleep 0.05
done

echo "Verification complete."
