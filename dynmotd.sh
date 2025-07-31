#!/bin/bash

echo -e "
+++++++++++++++++++: Hardware Info :+++++++++++++++++++
CPU     = $(cat /proc/cpuinfo | grep -m1 "model name" | awk -F ":" '{print $NF}')
uArch   = $(cat /proc/cpuinfo | grep -E -m1 -w -o 'sse|sse2|sse3|ssse3|sse4_1|sse4_2|avx|fma|avx512' | tr -t '\n' ' ')
Sockets = $(cat /proc/cpuinfo | grep "physical id" | sort -u | wc -l)
Cores   = $(cat /proc/cpuinfo | grep "processor" | wc -l)
Memory  = $(cat /proc/meminfo | grep "MemTotal" | awk '{printf ("%.2f GB",$2/1000/1000)}')
Caches :
   L1 = $(cat /sys/devices/system/cpu/cpu0/cache/index0/size)
   L2 = $([ -f "/sys/devices/system/cpu/cpu0/cache/index2/size" ] && cat /sys/devices/system/cpu/cpu0/cache/index2/size || echo "None")
   L3 = $([ -f "/sys/devices/system/cpu/cpu0/cache/index3/size" ] && cat /sys/devices/system/cpu/cpu0/cache/index3/size || echo "None")
Intel MIC  : $(lspci | grep -c -i "co-processor")
nVidia GPU : $(lspci | grep -i vga | grep -c -i "nvidia")

+++++++++++++++++++: System Info :+++++++++++++++++++++
Hostname        = $(hostname -f)
IP Address      = $(hostname -i)
Kernel/OS       = $(uname -r)
GCC             = $(gcc -dumpversion)
Uptime          = $(uptime)

+++++++++++++++++++: User Info :++++++++++++++++++++++
Username     = $(whoami)
Groups       = $(groups)
Local space  = $( [ -d "/export/users/$(whoami)" ] && echo "/export/users/$(whoami)" || echo "Local disk space can be created under /export/users/$(whoami)")
Shared space = $( [ -d "/project/$(whoami)" ] && echo "/project/$(whoami)" || echo "Shared disk space can be created under /project/$(whoami)")

+++++++++++++++++++: MKL NFS mounts :+++++++++++++++++
SW Tools           : /nfs/site/proj/mkl/mirror/NN/tools/
Intel Compilers    : /nfs/site/proj/mkl/mirror/NN/tools/intel/
IML testbases      : /nfs/site/proj/mkl/mirror/NN/MKLQA/testbase/
MKL nightly builds : /nfs/site/proj/mkl/builds/nightly/
Oregon builds      : /net/nwfs001/vol/vol1/PLL2/mkl/OR_build/

+++++++++++++++++++: Performance Settings :+++++++++++
Hyper-threading = $(siblings=$(cat /proc/cpuinfo | grep -m1 "siblings" | awk -F ":" '{print $NF}');cores=$(cat /proc/cpuinfo | grep -m1 "cpu cores" | awk -F ":" '{print $NF}'); [ "$siblings" == "$cores" ] && echo "OFF" || echo "ON")
CPU governor    = $([ -d "/sys/devices/system/cpu/cpu0/cpufreq" ] && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor || echo "System does not support scaling governor")
NUMA settings :
$(numactl -H)

+++++++++++++++++++: Usage guidelines :++++++++++++++++
This machine is part of the ECDL lab pool used by Intel Performance Libraries team (MKL, Numerics) developers.
Before using this machine, time slot should be reserved.
Machine reservations are done through ilab.intel.com under \"SSG_DPD_ECDL_JF\" client farm.
For furthur assistance, please contact the lab admin at Elzie, JeromeX L <jeromex.l.elzie@intel.com>
"
