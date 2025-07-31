#!/bin/bash

if [ -z $1 ]; then
   echo -e "USAGE: $0 <path-to-log-file>\nValid log files are from mpiP, onetrace and nsys tools"
   exit
fi

in_file=$1

if [[ ! -f ${in_file} ]]; then
   echo "${in_file} not found"
   exit
fi


#Identify log file
is_mpiP=$(grep -c "^@.*mpiP" $in_file)
is_onetrace=$(grep -c "=== API Timing Results: ===" $in_file)

#nsys stats --report cudaapisum,gpusum,gpumemsizesum,openaccsum,openmpevtsum report1.nsys-rep
is_nsys=$(grep -E -c 'cudaapisum|gpusum|gpumemsizesum|gpumemtimesum|openaccsum|openmpevtsum' $in_file)

function parse_mpiP_log()
{
  echo -e "Parsing mpiP log..\n"
  num_mpi=$(grep -c "^@.*MPI Task Assignment" ${in_file})
  grep -A$(($num_mpi+3)) "^@--- MPI Time (seconds)" ${in_file}
  # grep -A12 "@--- Aggregate Time (top twenty, descending, milliseconds)" ${in_file} | sed 's/twenty/ten/'
}

function parse_nsys_log()
{
  echo -e "Parsing nsys log..\n"
# cudaapisum -- CUDA API Summary
# gpusum[:base|mangled] -- GPU Summary (kernels + memory operations)
# gpumemsizesum -- GPU Memory Operations Summary (by Size)
# openaccsum -- OpenACC Summary
# openmpevtsum -- OpenMP Event Summary

  total_cuda_time=$(awk '/cudaapisum.py/,/gpusum.py/'     ${in_file} | grep -v -E 'Running|Time|---'  | tr -d ","  | awk 'BEGIN{s=0} {s+=$2;} END{print s}')
  total_dev_time=$(awk '/gpusum.py/,/gpumemsizesum.py/'   ${in_file} | grep -v -E 'Running|Time|---'  | tr -d ","  | awk 'BEGIN{s=0} {s+=$2;} END{print s}')
  pcent_dev_by_cuda=$(echo "scale=2; ${total_dev_time}/${total_cuda_time}*100" | bc -l);
  echo "Total time spent in CUDA APIs (ns) = ${total_cuda_time}"
  echo "Total time spent executing kernels + mem ops on GPU (ns) = ${total_dev_time} (${pcent_dev_by_cuda}% of CUDA time)"

  awk '/gpumemsizesum.py/,/gpumemtimesum.py/' ${in_file} | grep -v -E 'Running|Total|---' | tr -d ","  | awk 'BEGIN{s=0} {s+=$1;} END{printf ("Total bytes transferred to/from GPU = %ld MB\n",s);}'
  awk '/gpumemtimesum.py/,/openaccsum.py/'    ${in_file} | grep -v -E 'Running|Time|---'  | tr -d ","  | awk 'BEGIN{s=0} {s+=$2;} END{printf ("Total time spent in data transfers to/from GPU (ns) = %ld\n",s);}'
  awk '/openaccsum.py/,/openmpevtsum.py/'     ${in_file} | grep -v -E 'Running|Time|---'  | tr -d ","  | awk 'BEGIN{s=0} {s+=$2;} END{printf ("Total OpenACC time (ns) = %ld\n",s);}'
  awk '/openmpevtsum.py/,/EOF/'               ${in_file} | grep -v -E 'Running|Time|---'  | tr -d ","  | awk 'BEGIN{s=0} {s+=$2;} END{printf ("Total OpenMP time (ns) = %ld\n",s);}'
}

function parse_onetrace_log()
{
  echo -e "Parsing onetrace log..\n"
  total_exe_time=$(grep -m1 "Total Execution Time" ${in_file}             | awk '{print $NF}')

  total_l0_time=$(grep -m1 "Total API Time for L0 backend" ${in_file}     | awk '{print $NF}' | tr -d " ")
  if [ -z "${total_l0_time}" ]; then
    total_l0_time=0
  fi

  total_cl_time=$(grep -m1 "Total API Time for CL GPU backend" ${in_file} | awk '{print $NF}' | tr -d " ")
  if [ -z "${total_cl_time}" ]; then
    total_cl_time=0
  fi

  total_api_time=$((${total_l0_time}+${total_cl_time}))

  total_dev_time=$(grep -m1 "Total Device Time for L0 backend" ${in_file} | awk '{print $NF}' | tr -d " ")
  if [ -z "${total_dev_time}" ]; then
    total_dev_time=$(grep -m1 "Total Device Time for CL GPU backend" ${in_file} | awk '{print $NF}')
  fi

  pcent_api_by_exe=$(echo "scale=2; ${total_api_time}/${total_exe_time}*100" | bc -l);
  pcent_dev_by_api=$(echo "scale=2; ${total_dev_time}/${total_api_time}*100" | bc -l);

  echo "Total wall-clock time of executable (ns) = $total_exe_time"
  echo "Total time spent in L0/CL API's (ns)     = $total_api_time (${pcent_api_by_exe}% of wall-time)"
  echo "Total time spent executing kernels + mem ops on GPU (ns) = $total_dev_time (${pcent_dev_by_api}% of L0/CL APIs time)"
}


if [ "${is_mpiP}" != "0" ]; then
   parse_mpiP_log
elif [ "${is_onetrace}" != 0 ]; then
   parse_onetrace_log
elif [ "${is_nsys}" != "0" ]; then
   parse_nsys_log
else
   echo "Unknown log file"
   exit
fi
   
