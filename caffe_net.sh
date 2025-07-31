#!/bin/bash

[ -z $1 ] && { echo "[USAGE]: $0 path_to_input_file"; exit 1; }
[ ! -f $1 ] && { echo "[ERROR]: Input file not found!"; exit 1; }

num_layers=$(grep -c "layer[[:space:]]*{" $1)

echo -e "Name\tType\tEngine\tOuput\tPad\tKernel_Size\tStride\tPool\tBottom\tTop"

for ((i=1;i<=num_layers;i++));
do
	l_info=$(awk -v lid=$i 'BEGIN{RS="\n+}+\n+layer";FS="\n"} FNR == lid {print $0}' $1)

	l_name=$(  echo "${l_info}" | grep -w "name:"        | awk '{print $NF}' | tr -d '"' | tr "\n" " ")
	l_type=$(  echo "${l_info}" | grep -w -m1 "type:"    | awk '{print $NF}' | tr -d '"' | tr "\n" " ")
	l_engine=$(echo "${l_info}" | grep -w "engine:"      | awk '{print $NF}' | tr -d '"' | tr "\n" " ")
	l_output=$(echo "${l_info}" | grep -w "num_output:"  | awk '{print $NF}' | tr -d '"' | tr "\n" " ")
	l_pad=$(   echo "${l_info}" | grep -w "pad:"         | awk '{print $NF}' | tr -d '"' | tr "\n" " ")
	l_kernel=$(echo "${l_info}" | grep -w "kernel_size:" | awk '{print $NF}' | tr -d '"' | tr "\n" " ")
	l_stride=$(echo "${l_info}" | grep -w "stride:"      | awk '{print $NF}' | tr -d '"' | tr "\n" " ")
	l_pool=$(  echo "${l_info}" | grep -w "pool:"        | awk '{print $NF}' | tr -d '"' | tr "\n" " ")
	l_bottom=$(echo "${l_info}" | grep -w "bottom:"      | awk '{print $NF}' | tr -d '"' | tr "\n" " ")
	l_top=$(   echo "${l_info}" | grep -w "top:"         | awk '{print $NF}' | tr -d '"' | tr "\n" " ")

	echo -e "$l_name\t$l_type\t$l_engine\t$l_output\t$l_pad\t$l_kernel\t$l_stride\t$l_pool\t$l_bottom\t$l_top"
done

#Exclude top-1,top-5 accuracy layers
