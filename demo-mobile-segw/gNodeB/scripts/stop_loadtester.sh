#!/bin/bash

ip netns exec untrusted ipsec stop 2> /dev/null
ip -n untrusted xfrm state flush
ip -n untrusted xfrm policy flush
ip -n untrusted address flush dev lo
ip -n untrusted address add 127.0.0.1/8 scope host dev lo
