#!/bin/bash
set -euo pipefail
urls=()

# Here we use awk to prevent backslashes in an url from messing something up.
while read -r line; do
	urls+=("$line")
done < <(python scraper.py | head | awk -F// '{print $2}')

for i in "${!urls[@]}"; do
	# Website URL
	#urls[i]=$(echo "${urls[i]}" | awk -F// '{print $2}')
	echo "${urls[i]}"
	# Website name
	echo "${urls[i]}" | awk -F. '{print $2}'
	# Streamer channel name
	echo "${urls[i]}" | awk -F/ '{print $NF}'
	echo ""
done
