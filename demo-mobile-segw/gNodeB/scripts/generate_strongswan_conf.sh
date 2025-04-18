#!/bin/bash

if [ $tunnelstarget -le $initiators ]; then
	safeinit=1
	safetunnels=$tunnelstarget
else
	safeinit=$initiators
	safetunnels=$(($tunnelstarget / $initiators))
fi

mkdir -p /etc/netns/untrusted/ike/
touch /etc/netns/untrusted/ike/ipsec.conf
cp -r /etc/ike/strongswan.d /etc/netns/untrusted/ike/
cat << EOF > /etc/netns/untrusted/ike/strongswan.conf
charon {
        load_modular = yes
        threads = 64
        install_routes = no
        routing_table = 0
        make_before_break = yes
        install_virtual_ip = yes
        install_virtual_ip_on = lo
        ikesa_table_segments = 256
        ikesa_table_size = 16384
        replay_window = 4096
        plugins {
            include strongswan.d/charon/*.conf
            load-tester {
                load = yes
                enable = yes
                initiators = $safeinit
                iterations = $safetunnels
                delay = $delay
                dpd_delay = 60
		init_limit = $init_limit
                responder = 55.55.55.1
                initiator_id = tn$i-c%d-r%d-clt
                responder_id = *
                proposal = $proposal
		esp = $esp
                initiator_auth = pubkey
                responder_auth = pubkey
		issuer_cert = /etc/certificates/load-tester/6WIND_CA.cer
		issuer_key = /etc/certificates/load-tester/6WIND_CA.key
                fake_kernel = no
                ike_rekey = 0
                child_rekey = 0
                delete_after_established = no
                shutdown_when_complete = no
                initiator_tsr = 77.77.77.1/32
                request_virtual_ip = yes
                addrs {
                    loopback0 = 110.1.0.0/16
                }
                addrs_random = yes
                addrs_keep = yes
                addrs_prefix = 32
            }
            kernel-netlink {
              spdh_thresh {
                ipv4 {
                  lbits = 32
                  rbits = 32
                }
                ipv6 {
                  lbits = 128
                  rbits = 128
                }
              }
              xfrm_acq_expires = 30
              receive_buffer_size = 67108864
              force_receive_buffer_size = yes
            }
            socket-default {
              receive_buffer_size = 67108864
              force_receive_buffer_size = yes
            }
        }
	syslog { daemon { default = -1 } }
}
charon-systemd {
	customlog { journal { default = -1 } }
}
EOF
