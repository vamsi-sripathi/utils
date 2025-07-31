#!/bin/sh 
[ -z "$1" ] && { echo "specify scaling governor type!"; exit 1; }

policy=$1 
if [ ! -d /sys/devices/system/cpu/cpu0/cpufreq ]; then 
echo "This system doesn't have changing frequency capability." 
exit 1; 
fi 
echo 
echo "Available Policy : " `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors` 
echo 
cpus="/sys/devices/system/cpu/cpu[0-9]*" 
for i in ${cpus} 
do 
echo Setting CPU Policy on $i to $policy 
echo $policy > $i/cpufreq/scaling_governor 
done
