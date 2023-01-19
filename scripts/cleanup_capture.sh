#!/bin/bash
rm -f pipes/*

if [[ $1 == "a" ]]; then
	sudo podman stop -a
fi
