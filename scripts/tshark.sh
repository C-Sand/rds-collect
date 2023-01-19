#!/bin/bash
# Collection of ways we used tshark to capture traffic. When capturing udp.length, makes sure to remove the UDP and WireGuard header/oveheard later. (40bit)

# tshark -i <network-interface> -l -T fields -e frame.time_relative -e ip.addr -e frame.len >>tsharktest.txt
# tshark -i <network-interface> -l -T fields -e frame.time_relative -e ip.addr -e udp.length >>tshark_test.pcap
# tshark -i <network-interface> -l -T fields -e frame.time_relative -e ip.addr -e udp.length >>tshark_test.pcap 2>/dev/null

# RAM saving version. Make sure to create pipes before running and then cleanup pipes (fifo) after the capture is done.
tshark -i -w myfifo <network-interface >-l 2>/dev/null &
tshark -r myfifo -l -T fields -e frame.time_relative -e ip.addr -e udp.length >>tshark_test.pcap 2>/dev/null
