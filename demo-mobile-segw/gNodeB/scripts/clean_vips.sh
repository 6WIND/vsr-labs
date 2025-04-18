#!/bin/bash

tunnels=0
while [ $tunnels -lt $tunnelstarget ]
do
	addr=`ip netns exec untrusted ip address show dev lo | grep -E '7\.[0-9]*\.[0-9]*\.[0-9]*/32' | cut -d' ' -f 6`
	for ip in $addr
	do
		ip -n untrusted address del $ip dev lo
		tunnels=$((tunnels+1))
	done
done

echo "$tunnels IP addresses deleted"
