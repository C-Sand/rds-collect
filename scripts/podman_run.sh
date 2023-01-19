#!/bin/bash
#sudo podman run -it --rm --privileged -d --entrypoint=/configFiles/startup.sh --name="container_$i" debian_collect
sudo podman run -it --rm --privileged -d --entrypoint=/configFiles/startup.sh --name="container_1" debian_collect

while [ "$(podman inspect --format '{{.State.Status}}' container_1)" != "running" ]; do
	echo "Sleeping..."
	sleep 1
done
echo "Container finished starting"

# sudo podman run -it --rm --privileged -d --entrypoint=/configFiles/startup.sh debian_collect

# sudo podman stop a
