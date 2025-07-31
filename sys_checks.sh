#!/bin/bash
set -v
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

cat /sys/devices/system/cpu/cpufreq/boost
cat /sys/devices/system/cpu/intel_pstate/no_turbo

cat /sys/kernel/mm/*transparent_hugepage/enabled
cat /proc/sys/vm/nr_hugepages
grep -i HugePages_Total /proc/meminfo
