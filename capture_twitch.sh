#!/bin/bash

if [ $# != 3 ]; then
	echo "Usage: $0 <capture time> <number of containers> <container image id>"
	exit 0
fi

# Get todays date in: yyyy-mm-dd
DATE=$(date '+%Y-%m-%d')
urls=()
capture_time=$1 # Decide how long to run the capture. Specify with format with h, m or s.
service=()
service_type="stream"
streamer=()
capture_program="tshark"
network_interfaces=()
PID=()
containers=()
fifo=()
kplus1=0

# Create files before we get root so that the user is the owner.
mkdir -p "logs"
mkdir -p "captures"
mkdir -p "pipes"
logfile="logs/capture_log_${DATE}.log"
touch "$logfile"

log() {
	current_timedate=$(date '+%Y-%m-%d %H:%M:%S')
	printf '%s | %b\n' "$current_timedate" "$1" >>"$logfile"
}

# Prompt for root access so podman and tshark can run, just in case the user runs the script manually.
if [ $EUID != 0 ]; then
	sudo "$0" "$@"
	exit $?
fi

log "Starting"
log "Grabbing streams from twitch.tv"
readarray -t urls < <(python3 scraper.py | head -n "$2" | awk -F// '{print $2}')
log "Grabbed ${#urls[*]} streams\n"

for m in "${!urls[@]}"; do
	service[m]=$(echo "${urls[m]}" | awk -F. '{print $2}')
	streamer[m]=$(echo "${urls[m]}" | awk -F/ '{print $NF}')
done

# Start containers based on built image
for k in "${!urls[@]}"; do
	kplus1=$((k + 1))
	(
		cd debian_collect || exit
		cp "configFiles/mullvad_$kplus1.conf" configFiles/mullvad.conf

		echo "#!/bin/bash
wg-quick up mullvad
curl https://am.i.mullvad.net/connected
firefox -headless \"${urls[k]}\"" >configFiles/startup.sh

		sudo podman run -i -d --rm --privileged --mount type=bind,src=configFiles,target=/etc/wireguard --entrypoint etc/wireguard/startup.sh --name="container_$kplus1" "$3"
	)
	containers[k]="container_$kplus1"
	log "Running container with name: ${containers[k]}"
	log "Visiting URL: ${urls[k]}"
done
log "$kplus1 containers started\n"

log "Grabbing container interfaces...\n"
# Grab all virtual network interfaces for the containers running
# Containers set up with mcvlan gets their own interfaces with the
# interface names starting with veth. So we just grep that
readarray -t network_interfaces < <(ip -br -o a | grep -o "\w*veth\w*")

# Start capture and save to $outFile.
for i in "${!network_interfaces[@]}"; do
	outFile="captures/${capture_program}_${capture_time}_${service[i]}-${streamer[i]}_${service_type}_${DATE}"
	if test -f "$outFile.log"; then
		#log "File already exists. Creating new..."
		counter=1
		while [[ -f "${outFile}_${counter}.log" ]]; do
			((counter++))
		done
		outFile="${outFile}_${counter}"
	fi
	outFile="$outFile.log"
	touch "$outFile"
	log "Creating capture file: $outFile"
	log "Capturing on interface: ${network_interfaces[i]}"
	# Create a named pipe so tshark doesn't eat all our RAM
	fifo[i]="fifo$i"
	mkfifo "pipes/${fifo[i]}"
	# Send tshark stdout to outFile and tshark stderror to the void so it doesn't flood the terminal.
	timeout "${capture_time}" bash -k -c "tshark -i ${network_interfaces[i]} -l -w pipes/${fifo[i]} 2>/dev/null & tshark -r pipes/${fifo[i]} -l -T fields -e frame.time_relative -e ip.addr -e udp.length >>$outFile 2>/dev/null" &
	# -k = Part of timeout, kill process if it's still running afterwards.
	# -c = Read command from string. Since here were running it inside "".
	PID[i]=$!
	log "Name and PID on ${network_interfaces[i]}: ${containers[i]} ${PID[i]}\n"
done

# Put a wait on jobs so we can log when they are finished.
for j in "${!network_interfaces[@]}"; do
	wait "${PID[j]}"
	log "${PID[j]} ${containers[j]} with time ${capture_time} has finished capturing"
done
wait

log "Finished running all capture"
log "Cleaning up pipes..."
rm -f pipes/*
wait
log "Stopping containers..."
sudo podman stop -a
wait
log "Stopped containers"
log "Exiting\n"
exit
