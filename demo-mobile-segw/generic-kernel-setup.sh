#!/bin/bash

# Run this script if you have an non generic kernel
# MPLS and VRF capabilities are not part of the kernel in the default Ubuntu AMI

sudo apt-get update
sudo apt-get install -y linux-image-generic

vmlinuz=$(sudo find /boot -name "*vmlinuz*generic")
initrd=$(sudo find /boot -name "*init*generic")
cmdline=$(cat /proc/cmdline | sed 's/[^ ]*BOOT_IMAGE[^ ]*//g')

sudo apt install -y kexec-tools

sudo kexec -l $vmlinuz --initrd $initrd --command-line "$cmdline"
sudo systemctl kexec
