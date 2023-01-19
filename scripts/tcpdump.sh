#!/bin/bash
#tcpdump command to catch data from host IP in our preffered format
#This script was only used at the beginning of the project
tcpdump -qlttttt -i any host 10.10.10.10 | awk '{printf "%s,", $1}; {gsub("In","r",$3)}; {gsub("Out","s",$3)}; {printf "%s,", $3};{printf "%d\n",$10}; system("")' > test1.txt