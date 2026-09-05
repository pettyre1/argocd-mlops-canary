#!/bin/bash


# Default port is 8080
URL="http://localhost:8080/extract-entities"

# payload
JSON_PAYLOAD='{"text": "Applied Research Associates"}'

echo "Starting synthetic traffic generator..."
echo "Sending POst requests to $URL"
echo "Press Ctrl+c to stop"
echo "----------------------------------------------"

while true; do
  # The -w flag formats to output to show response time and HTTP status code
  curl -s -w "\n[Status: %{http_code}] [Latency: %{time_total}s]\n------------------------------------------------------\n" \
       -X POST "$URL" \
       -H "Content-Type: application/json" \
       -d "$JSON_PAYLOAD"

  # Pause 0.5 seconds between requests to simulate stead load
  sleep 0.5
done
