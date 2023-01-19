#!/bin/bash

if [ $# != 2 ]; then
	echo "Usage: $0 <capture.conf> <container image id>"
	exit 0
fi

# Get todays date in: yyyy-mm-dd
DATE=$(date '+%Y-%m-%d')
url=()
capture_time=() # Decide how long to run the capture. Specify with format with h, m or s.
service=()
service_type=()
capture_program=()
network_interfaces=()
PID=()
containers=()
fifo=()
# mullvad_configs=()

# Create files before we get root so that the user is the owner.
mkdir -p "logs"
mkdir -p "pcaps"
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

log "Starting up"
# Read capture info from capture.conf
read_counter=0
while read -r line; do
	IFS=' ' read -r "url[read_counter]" "capture_time[read_counter]" "service[read_counter]" "service_type[read_counter]" "capture_program[read_counter]" rest <<<"$line"
	((read_counter++))
done <"$1"

((read_counter--))
log "Read $read_counter containers from config"

# Start containers based on built image
# Here were also changing the mullvad config and startup files to match capture.conf
for k in $(seq 1 "$read_counter"); do
	(
		cd debian_collect || exit
		cp "configFiles/mullvad_$k.conf" configFiles/mullvad.conf

		echo "#!/bin/bash
wg-quick up mullvad
curl https://am.i.mullvad.net/connected
firefox -headless \"${url[k]}\"" >configFiles/startup.sh

		sudo podman run -i -d --rm --privileged --mount type=bind,src=configFiles,target=/etc/wireguard --entrypoint etc/wireguard/startup.sh --name="container_$k" "$2"
		wait$!
	)
	containers[k - 1]="container_$k"
	log "Running container with name: ${containers[k - 1]}"
	log "Visiting URL: ${url[k - 1]}"
done
log "$k containers started\n"

log "Grabbing container interfaces...\n"
# Grab all virtual network interfaces for the containers running
# Containers set up with mcvlan gets their own interfaces with the
# interface names starting with veth. So we just grep that
readarray -t network_interfaces < <(ip -br -o a | grep -o "\w*veth\w*")
# Grab all network interfaces instead with command below. In case you want to.
# readarray -t network_interfaces < <(ip -br -o a | awk '{print $1}')

# Start capture and save to $outFile.
for i in "${!network_interfaces[@]}"; do
	outFile="pcaps/${capture_program[i]}_${capture_time[i]}_${service[i]}_${service_type[i]}_${DATE}"
	if test -f "$outFile.pcap"; then
		#log "File already exists. Creating new..."
		counter=1
		while [[ -f "${outFile}_${counter}.pcap" ]]; do
			((counter++))
		done
		outFile="${outFile}_${counter}"
	fi
	outFile="$outFile.pcap"
	touch "$outFile"
	log "Creating capture file: $outFile"
	log "Capturing on interface: ${network_interfaces[$i]}"
	# Create a named pipe so tshark doesn't eat all our RAM
	fifo[i]="fifo$i"
	mkfifo "pipes/${fifo[i]}"
	# Send tshark stdout to outFile and tshark stderror to the void so it doesn't flood the terminal.
	timeout "${capture_time[i]}" bash -k -c "tshark -i ${network_interfaces[i]} -l -w pipes/${fifo[i]} 2>/dev/null & tshark -r pipes/${fifo[i]} -l -T fields -e frame.time_relative -e ip.addr -e udp.length >>$outFile 2>/dev/null" &
	# -k = Part of timeout, kill process if it's still running afterwards.
	# -c = Read command from string. Since here were running it inside "".
	PID[i]=$!
	log "Name and PID on ${network_interfaces[i]}: ${containers[i]} ${PID[i]}\n"
done

# Put a wait on jobs so we can log when they are finished.
for j in "${!network_interfaces[@]}"; do
	wait "${PID[j]}"
	log "${PID[j]} ${containers[j]} with time ${capture_time[j]} has finished capturing."
done
wait

log "Finished running all capture."
log "Cleaning up pipes..."
rm -f pipes/*
wait
log "Stopping containers..."
sudo podman stop -a
wait
log "Stopped containers"
log "Exiting\n"
exit
