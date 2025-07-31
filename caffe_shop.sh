#!/bin/bash
#set -o nounset

function usage
{
  echo "USAGE: $0 --key=value"
  echo "Valid keys are:"
  echo -e "\t--mode=[score, train, tttrain]"
  echo -e "\t--topology=[alexnet, convnet-alexnet, convnet-googlenet, convnet-vgg, googlenet-v1, resnet-50, vgg-19]"
  echo -e "\t--data_source=[lmdb, dummy]"
  echo -e "\t\tDetermines whether real dataset is read from file-system or random numbers are populated in memory"
  echo -e "\t--batch_size=[positive number]"
  echo -e "\t--iterations=[positive number]"
  echo -e "\t--cache_data=[0, 1]"
  echo -e "\t\t Determines whether LMDB dataset is cached into memory before benchmarking begins"
  echo -e "\t--num_threads=[positive number]"
  echo -e "\t\tIf not specified, the default number of threads is equal to physical number of cores"
  echo -e "\t--numa_opts=[whatever options numactl provides]"
  echo -e "\t\tIf not specified, the default is to use MCDRAM for Xeon Phi (i.e., -m 1 if machine state is in Flat Mode) and local memory (-l) for Xeon"
  echo -e "\t--help"
  return
}

function read_options
{
  for ((i=0; i<${#input_args[*]}; i++))
  do
    key=`echo ${input_args[$i]} | cut -f 1 -d "="`
    value=`echo ${input_args[$i]} | cut -f 2 -d "="`
    case $key in
      --mode)
        mode=$value
        ;;
      --topology)
        topology=$value
        ;;
      --data_source)
        data_source=$value
        ;;
      --batch_size)
        batch_size=${value}
        ;;
      --iterations)
        iterations=$value
        ;;
      --num_threads)
        num_threads=$value
        ;;
      --cache_data)
        cache_data=$value
        ;;
      --numa_opts)
        numa_opts=$value
        ;;
      --help | -h)
        usage
        exit 1;
        ;;
      *)
        echo "ERROR: $key is an unknown option"
        exit 1;
        ;;
    esac
  done
}


function set_host_info
{
# Check uArch
  grep -m1 avx512f /proc/cpuinfo | grep avx512dq | grep avx512cd | grep avx512bw | grep avx512vl &> /dev/null
  [ "$?" -eq "0" ] && host_arch=skx

  grep -m1 avx512f /proc/cpuinfo | grep avx512pf | grep avx512er | grep avx512cd &> /dev/null
  [ "$?" -eq "0" ] && host_arch=knl

  grep -m1 avx512_4vnniw /proc/cpuinfo | grep avx512_4fmaps &> /dev/null
  [ "$?" -eq "0" ] && host_arch=knm

# Check compute units
  host_model_name=$(lscpu_lookup "Model name")
  host_sockets=$(lscpu_lookup "Socket(s)")
  host_cores_per_socket=$(lscpu_lookup "Core(s) per socket")
  host_threads_per_core=$(lscpu_lookup "Thread(s) per core")

# Check memory sub-system
  host_memory=$(cat /proc/meminfo | grep "MemTotal" | awk '{printf ("%.2f GB",$2/1000/1000)}')
  host_l1_cache=$(lscpu_lookup "L1d cache")
  host_l2_cache=$(lscpu_lookup "L2 cache")
  host_l3_cache=$(lscpu_lookup "L3 cache")
  if [[ "$host_arch" == "knl"  || "$host_arch" == "knm" ]]; then
    host_mcdram_size=$( hwloc-dump-hwdata | grep "Total MCDRAM" | awk '{print $3 $4}')
    host_mcdram_cluster_mode=$( hwloc-dump-hwdata | grep "Cluster Mode:" | awk '{print $3}')
    host_mcdram_memory_mode=$( hwloc-dump-hwdata | grep "Memory Mode:" | awk '{print $NF}')
  fi

# Check HT
  host_phy_cores=$((${host_sockets}*${host_cores_per_socket}))
  host_logical_cores=$((${host_phy_cores}*${host_threads_per_core}))
  if [ "$host_threads_per_core" -gt "1" ]; then
    host_hyper_threading=1
  else
    host_hyper_threading=0
  fi

#Check Turbo
  if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
    [ "$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)" -eq "0" ] && host_turbo=1 || host_turbo=0
  fi

#check Scaling Info
  host_scaling_governor=$([ -d "/sys/devices/system/cpu/cpu0/cpufreq" ] && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
  host_scaling_min_freq=$([ -d "/sys/devices/system/cpu/cpu0/cpufreq" ] && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)
  host_scaling_max_freq=$([ -d "/sys/devices/system/cpu/cpu0/cpufreq" ] && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)
}

function print_hw_info()
{
  hw_info_log_file=${RESULT_DIR}/hw_info.log
  echo "Hardware Info:" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tModel:  ${host_model_name}" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tSockets ${host_sockets}" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tCPU Architecture: ${host_arch}" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tCores/socket: ${host_cores_per_socket}" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tThreads/Core: ${host_threads_per_core}" 2>&1 | tee -a ${hw_info_log_file}

  echo -e "\tMemory: ${host_memory}" 2>&1 | tee -a ${hw_info_log_file}
  if [[ "${host_arch}" == "knl" || "${host_arch}" == "knm" ]]; then
    echo -e "\tMCDRAM: ${host_mcdram_memory_size}" 2>&1 | tee -a ${hw_info_log_file}
    echo -e "\tMCDRAM Memory Mode:  ${host_mcdram_memory_mode}" 2>&1 | tee -a ${hw_info_log_file}
    echo -e "\tMCDRAM Cluster Mode: ${host_mcdram_cluster_mode}" 2>&1 | tee -a ${hw_info_log_file}
  fi
  echo -e "\tL1 Cache: ${host_l1_cache}" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tL2 Cache: ${host_l2_cache}" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tL3 Cache: ${host_l3_cache}" 2>&1 | tee -a ${hw_info_log_file}

  echo -e "\tHyper-Threading: ${host_hyper_threading}" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tTurbo: ${host_turbo}" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tCPU Scaling Governor: ${host_scaling_governor}" 2>&1 | tee -a ${hw_info_log_file}
  echo -e "\tCPU Scaling Range: ${host_scaling_min_freq} - ${host_scaling_max_freq}" 2>&1 | tee -a ${hw_info_log_file}
}

function flush_system_cache()
{
   sh -c 'rm -f /dev/shm/eplib* /dev/shm/psm2* ; sync ; echo 3 > /proc/sys/vm/drop_caches'
}

function cache_lmdbs()
{
  echo "INFO: Caching lmdb data..."
  if [ "$host_mcdram_memory_mode" == "Flat" ]; then
    numactl -m 1 cat "$LMDB_DIR/ilsvrc12_train_lmdb/data.mdb" > /dev/null
    numactl -m 1 cat "$LMDB_DIR/ilsvrc12_val_lmdb/data.mdb" > /dev/null
  else
    cat "$LMDB_DIR/ilsvrc12_train_lmdb/data.mdb" > /dev/null
    cat "$LMDB_DIR/ilsvrc12_val_lmdb/data.mdb" > /dev/null
  fi
  echo "INFO: Done caching lmdb data"
}

function lscpu_lookup
{
  echo $(lscpu | grep "$1" | awk -F ":" '{print $NF}' | tr -d "\t")
}


function benchmark_prep()
{
  echo "INFO: Flushing system caches.."
  flush_system_cache

  if [[ "$data_source" == "lmdb" && "$cache_data" -eq "1" ]]; then
    cache_lmdbs
  fi

  if [[ -z "${numa_opts}" ]]; then
    if [[ "$host_arch" == "knl" || "$host_arch" == "knm" ]]; then
      numactl_mode='numactl -m 1'
    elif [[ "$host_arch" == "skx" ]]; then
      numactl_mode='numactl -l'
    else
      numactl_mode=''
    fi
  else
    echo "INFO: Using numa opts ${numa_opts}"
    numactl_mode="numactl ${numa_opts}"
  fi

#   cpupower frequency-info
  echo "INFO: Setting CPU min, max frequencies to ${host_scaling_min_freq}, ${host_scaling_max_freq} and governor to \"performance\""
   cpupower frequency-set --min ${host_scaling_min_freq} --max ${host_scaling_max_freq} --governor performance > /dev/null

# set Env. vars (OMP/KMP)
  [ -z "${num_threads}" ] && omp_num_threads=${host_phy_cores} || omp_num_threads=${num_threads}
  export OMP_NUM_THREADS=${omp_num_threads}

  [ "$host_hyper_threading" -eq "1" ] && export KMP_AFFINITY="granularity=fine,compact,1,0" || export KMP_AFFINITY=compact
  # [ "$host_hyper_threading" -eq "1" ] && export KMP_AFFINITY="granularity=fine,scatter,1,0" || export KMP_AFFINITY=compact

# Unset Intel OMP BLOCKTIME
  unset KMP_BLOCKTIME
    
# set SHELL env. for Compilers
  # export LD_LIBRARY_PATH=${CAFFE_DIR}/external/mkldnn/install/lib/:$LD_LIBRARY_PATH
  # export LD_LIBRARY_PATH=${CAFFE_DIR}/external/mkl/mklml_lnx_2017.0.2.20170110/lib:$LD_LIBRARY_PATH

#  . /opt/intel/parallel_studio/compilers_and_libraries_2017.4.196/linux/bin/compilervars.sh intel64
#  . /opt/intel/mlsl_2017.0.014/intel64/bin/mlslvars.sh

# 8180 nodes
  # . /opt/intel/parallel_studio_xe_2017.2.050/bin/psxevars.sh intel64
  # . /opt/intel/mlsl_2017.0.006/intel64/bin/mlslvars.sh
}

function generate_input_files()
{
  model_template="${MODEL_DIR}/${topology}/train_val_template_${data_source}.prototxt"

  if [ ! -f "$model_template" ]; then
    echo "ERROR: $model_template does not exist"
    exit 1
  fi

  mkdir -p "${RESULT_DIR}/prototxt/${topology}"

  model="${RESULT_DIR}/prototxt/${topology}/train_val_${data_source}_bs${batch_size}.prototxt"

  cat <<EOF > $model
#
# Auto-generated by script.
#
# To make changes, edit $model_template.
#
EOF

  sed "s/<<BATCH_SIZE>>/${batch_size}/" $model_template >> $model


  if [ "$mode" == "tttrain" ]; then
    solver_template="${MODEL_DIR}/${topology}/solver_template.prototxt"
    if [ ! -f "$solver_template" ]; then
      echo "ERROR: $solver_template does not exist"
      exit 1
    fi

    solver="${RESULT_DIR}/prototxt/${topology}/solver_${data_source}_bs${batch_size}_${iterations}iters.prototxt"
    snapshot="${RESULT_DIR}/prototxt/${topology}/snapshot_${mode}_${data_source}_bs${batch_size}_${iterations}iters_snapshot"

    cat <<EOF > $solver
#
# Auto-generated by script.
#
# To make changes, edit $solver_template.
#
EOF

  sed -e "s%<<TRAIN_VAL>>%${model}%" -e "s%<<MAX_ITER>>%${iterations}%" -e "s%<<SNAPSHOT_PREFIX>>%${snapshot}%" $solver_template >> $solver
  fi
}

function run_experiment()
{
  mkdir -p "${RESULT_DIR}/output/${topology}"

  output_file="${RESULT_DIR}/output/${topology}_${mode}_${data_source}_bs${batch_size}_nt${omp_num_threads}_cache${cache_data}.out"
  stats_file="${RESULT_DIR}/output/${topology}_${mode}_${data_source}_bs${batch_size}_nt${omp_num_threads}_cache${cache_data}.stats"
  exp_info_log_file="${RESULT_DIR}/output/${topology}_${mode}_${data_source}_bs${batch_size}_nt${omp_num_threads}_cache${cache_data}.exp"

  echo "Experiment Info:" 2>&1 | tee -a ${exp_info_log_file}
  echo -e "\tMode:        $mode" 2>&1 | tee -a ${exp_info_log_file}
  echo -e "\tTopology:    $topology" 2>&1 | tee -a ${exp_info_log_file}
  echo -e "\tData Layer:  $data_source" 2>&1 | tee -a ${exp_info_log_file}
  echo -e "\tBatch Size:  $batch_size" 2>&1 | tee -a ${exp_info_log_file}
  echo -e "\tIterations:  $iterations" 2>&1 | tee -a ${exp_info_log_file}
  echo -e "\tCache Data:  $cache_data (0 = false, 1 = true)" 2>&1 | tee -a ${exp_info_log_file}

  echo "Environment variables:" 2>&1 | tee -a ${exp_info_log_file}
  echo -e "OMP:\n$(env | grep -E 'OMP|KMP')" 2>&1 | tee -a ${exp_info_log_file}


  echo -e "\tOutput file: ${output_file}"
  echo -e "\tStats file:  ${output_file}"

  if [ "$mode" == "score" ]; then
    echo "INFO: Scoring with time command"
     $numactl_mode ${CAFFE_DIR}/build/tools/caffe time \
     -model "$model" -iterations $iterations \
     -engine MKL2017 \
     -forward_only 2>&1 | tee "$output_file"

     tail "$output_file" | egrep 'Average.*ward' > $stats_file
  elif [ "$mode" == "train" ]; then
    echo "INFO: Training with time command"
     $numactl_mode ${CAFFE_DIR}/build/tools/caffe time \
     -model "$model" -iterations $iterations \
     -engine MKL2017 2>&1 | tee "$output_file"

     tail "$output_file" | egrep 'Average.*ward' > $stats_file
  elif [ "$mode" == "tttrain" ]; then
    echo "INFO: TTT with train command"
     $numactl_mode ${CAFFE_DIR}/build/tools/caffe train \
     -solver "$solver" -iterations $iterations \
     -engine MKL2017 2>&1 | tee "$output_file"

     cat $output_file | grep Iteration | grep loss > $stats_file
  fi
}


CAFFE_DIR=$(pwd)
MODEL_DIR=$(pwd)/sample_topologies
LMDB_DIR=/data/local_data/

input_args=("$@")

if [[ -z "$1" ]]; then 
  usage
  exit 1;
fi

read_options

set_host_info

RESULT_DIR="$HOME/caffe_results/${host_arch}/${topology}/${mode}"

generate_input_files

benchmark_prep

print_hw_info

run_experiment

