#!/bin/bash

set -o errexit
function usage
{
	echo "PURPOSE: Decorate NETLIB BLAS sources to differentiate from MKL BLAS"
	echo "USAGE: $0 [path_to_NETLIB_BLAS] [destination_dir]"
}

if [[ -z $1 || $1 == "--help" || ! -d "$1" ]]; then
	usage
	exit
fi

decorate_prefix="NETLIB_"

mkdir -p $2
cp $1/*.f $2
cd $2

for i in *.f
do
	fname=`sed -n 1p $i | awk -F "(" '{ print $1 }' | awk '{ print $NF }'`
	l_fname=`echo "${fname,,}"`
	echo "INFO: Replacing ${fname} with ${decorate_prefix}${fname}"
	sed -i "s/${fname}/${decorate_prefix}${l_fname}/g" $i # Replaces SUBROUTINE, FUNCTION, values to functions in code
	ext_fname=(`grep EXTERNAL $i | awk -F "," '{ for (i=1;i<=NF;i++) print $i }'`)
	for ((j=0;j<${#ext_fname[@]};j++));
	do
		if [[ "${ext_fname[$j]}" == "EXTERNAL" ]]; then
			continue
		else
			l_ext_fname=`echo "${ext_fname[$j],,}"`
			sed -i "s/${ext_fname[$j]}/${decorate_prefix}${l_ext_fname}/g" $i; # Handle external function calls/declarations
		fi
	done
done
