from trex_stl_lib.api import *
import copy


class IMIXForward(object):

    macs = {
        "gnodeb":    "00:0c:c3:11:11:11",   # gNodeB MAC address
        "pe-core-1": "00:0c:c3:99:99:99",   # PE MAC address
    }

    imix_800_table = [
            {'size': 64,   'count': 0.41  },
            {'size': 96,   'count': 3.27  },
            {'size': 192,  'count': 3.68  },
            {'size': 384,  'count': 1.47  },
            {'size': 768,  'count': 86.92 },
            {'size': 1271, 'count': 4.09  },
            {'size': 1560, 'count': 0.16  },]

    def compute_bandwidth_percent(self, imixtable, entry):
        total_size = 0
        for imix_entry in imixtable:
            total_size += (imix_entry['size'] + 20) * 8 * imix_entry['count']
        return ((entry['size'] + 20) * 8 * entry['count'] / total_size)


    def oneway(self, total_percentage, imixtable, basepkt, offset, start, end):
        streams = []
        vm = STLScVmRaw([ STLVmFlowVar(name="ip_dst", min_value=start,
                                        max_value=end,
                                        size=4,
                                        step=1,
                                        op="inc"),
                           STLVmWrFlowVar(fv_name="ip_dst", pkt_offset= offset),
                           STLVmFixIpv4(offset = "IP") # fix checksum
                         ],
                       cache_size = 375
                    )
        for imix_entry in imixtable:
                pkt = basepkt / (max(0, imix_entry['size'] - len(basepkt)) * 'x')
                streams.append(STLStream(packet = STLPktBuilder(pkt = pkt, vm = vm),
                               mode = STLTXCont(percentage = total_percentage * (self.compute_bandwidth_percent(imixtable, imix_entry)))))
        return streams

    def get_streams(self, direction=0, **kwargs):
        streams = []
        cluster_size = 2
        bandwidth_upstream=1
        bandwidth_downstream=1
        port_id = kwargs.get('port_id')

        if port_id == 0:
            # Data stream upstream
            basepkt = Ether(dst=self.macs["gnodeb"])/IP(dst='77.77.77.1', proto=socket.IPPROTO_NONE)
            streams.extend(self.oneway((bandwidth_upstream / cluster_size), self.imix_800_table,  basepkt, "IP.src", '7.100.0.1', '7.100.2.200'))
            streams.extend(self.oneway((bandwidth_upstream / cluster_size), self.imix_800_table,  basepkt, "IP.src", '7.100.64.1', '7.100.66.200'))
            # Latency flow upstream
            basepkt = Ether(dst=self.macs["gnodeb"])/IP(src='7.100.0.1', dst='77.77.77.1')/UDP(dport=40000,sport=20000)/'at_least_16_bytes_are_needed'
            streams.append(STLStream(packet = STLPktBuilder(pkt = basepkt),flow_stats=STLFlowLatencyStats(pg_id=1),mode = STLTXCont(pps = 10)))  # Latency upstream
        elif port_id == 1:
            # Data stream downstream
            basepkt = Ether(dst=self.macs["pe-core-1"])/IP(src='77.77.77.1', proto=socket.IPPROTO_NONE)
            streams.extend(self.oneway((bandwidth_downstream / cluster_size), self.imix_800_table, basepkt, "IP.dst", '7.100.0.1', '7.100.2.200'))
            streams.extend(self.oneway((bandwidth_downstream / cluster_size), self.imix_800_table, basepkt, "IP.dst", '7.100.64.1', '7.100.66.200'))
        return streams

# dynamic load - used for trex console or simulator
def register():
    return IMIXForward()
