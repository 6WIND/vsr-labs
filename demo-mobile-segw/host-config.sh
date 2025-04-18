#!/bin/bash -e

#########################################################
#                  HOST CONFIGURATION                   #
#########################################################

KMODS="
br_netfilter
ebtables
ifb
ip6_tables
ip_tables
mpls_iptunnel
mpls_router
nf_conntrack
overlay
ppp_generic
vfio-pci
vhost-net
vrf
"

# For current boot
for kmod in $KMODS; do sudo modprobe $kmod; done
# Make it boot persistent
for kmod in $KMODS; do echo $kmod | sudo tee -a /etc/modules-load.d/vsr-hypervisor.conf; done

# Persisten Sysctl setting
sudo echo -e "fs.inotify.max_user_instances=2048\nfs.inotify.max_user_watches=1048576\nnet.core.rmem_max=134217728\nnet.netfilter.nf_log_all_netns=1\nvm.nr_hugepages = 3000" | sudo tee -a /etc/sysctl.conf
# Reload config for the current boot
sudo sysctl --system


#########################################################
#                 REQUIRED PACKAGES                     #
#########################################################

sudo apt-get update
sudo apt install -y sshpass screen ansible-core

#########################################################
#                  DOCKER Installation                  #
#########################################################

sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update 
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#########################################################
#               CONTAINERLAB Installation               #
#########################################################

sudo bash -c "$(curl -sL https://get.containerlab.dev)"

#########################################################
#               Create a keypair if needed              #
#########################################################

if ! [ -f $HOME/.ssh/id_rsa ]; then
	ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N ""
fi

#########################################################
#          Add user to the appropriate groups           #
#########################################################

sudo usermod -aG clab_admins $USER
sudo usermod -aG docker $USER


echo "***************************************************************************************"
echo "* Please log out and log in again to refresh the groups to which your user belongs to *"
echo "***************************************************************************************"
