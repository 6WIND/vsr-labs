#!/bin/bash

if [ -z $1 ]; then
   echo "Error: need one argument : the targeted number of tunnels"
   exit 1
else
   re='^[0-9]+$'
   if ! [[ $1 =~ $re ]] ; then
      echo "Error: the first parameter is not a number"
      exit 1
   fi
fi

tunnelstarget=$1
maxretries=100

source ./test-parameters
. ./generate_strongswan_conf.sh

echo "Start tunnel negociation: $(date)"

# Make sure we get sequential IPs from the pool for traffic VRF
echo "Starting load-tester in netns untrusted"
rm -f /etc/netns/untrusted/ike/ipsec.d/run/*
ip netns exec untrusted ipsec start
retry=0
nbtunnels=0
while [[ nbtunnels -lt $tunnelstarget && retry -lt $maxretries ]]
do
	sleep 1
	retry=$(($retry + 1))
	nbtunnels=`ip netns exec untrusted swanctl -l | grep -c INSTALLED`
done	

echo "End of tunnel negociation: $(date): number tunnels established: $nbtunnels"

echo "Cleaning VIPs"
. ./clean_vips.sh

echo "Ready"
