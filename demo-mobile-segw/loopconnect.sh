#!/bin/bash
#

# Time for the container to initialize
ssh $1
while test $? -gt 0
do
   sleep 5
   #echo "Trying again..."
   ssh $1
done
