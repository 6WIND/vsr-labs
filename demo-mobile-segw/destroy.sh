#!/bin/bash

screen -X -S `screen -ls | grep containerlab | awk '{print $1}'` quit

if [ "$1" == "--cleanup" ]
then
	containerlab destroy --graceful --cleanup
else
	containerlab save
	containerlab destroy --graceful
fi
rm -f pki/*
