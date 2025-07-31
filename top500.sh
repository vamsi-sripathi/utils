#!/bin/sh

# Re-direct output from this script to find missing data
opts="$*"
if [ -z "$opts" ]; then
	echo "USAGE: $0 [list_of_years | range_of_years]"
	echo "e.g.: $0 2009 2010 2011 2012  (OR) $0 2009-2012"
	exit
fi

echo $opts | grep "-" &>/dev/null
if [ $? -eq 0 ]; then
	start_year=$(echo $opts | awk -F "-" '{print $1}') 
	end_year=$(echo $opts | awk -F "-" '{print $2}')
	if [[ -z "$start_year" || -z "$end_year" ]]; then
		echo "USAGE: $0 start_year-end_year"
		exit 1
	fi
	range=$(seq ${start_year} ${end_year})
else
	range="$*"
fi

# set proxy for JF env
export http_proxy=http://proxy.jf.intel.com:911

month_list="06 11"

for year in $range
do
	for month in $month_list
	do
		list_id=${year}_${month}

# Check if data already exits and skip
		if [ -d "$list_id" ]; then
		   continue
		else
			mkdir -p $list_id
			cd $list_id
		fi

# Fetch list url in sets of 100
		curl http://www.top500.org/list/$year/$month/?page=[1-5] -o top_${list_id}_#1.html

# Check for transmission errors
		if [ $? -ne 0 ]; then
		   echo "ERROR: URL for $list_id not accessible" >> err.log
		   continue
		fi

# Check for corrupted data. TOP500 writes "Sorry, an error occurred." if list is not created
		grep -i "error" top_${list_id}_* &> /dev/null
		if [ $? -eq 0 ]; then
			echo "ERROR: Data unavailable for $list_id" >> err.log
			continue
		fi

# Iterate over each set of 100 
		count=0
		for sublist in 1 2 3 4 5
		do
			for i in `grep "<tr" -A 5 -m 101 top_${list_id}_${sublist}.html | grep "href=\"/system" | awk -F "\"" '{ print $2}'`
			do
				count=$(($count+1))
				wget -O rank-$count.html http://www.top500.org/$i 
				if [ $? -ne 0 ]; then
				   echo "ERROR: URL for rank-$count in $list_id is not accessible" >> err.log
				   continue
				fi
			done
		done

		grep "Math Library:" rank-*.html > mathLibraries.log
		sed -i '/<td><\/td>/d' mathLibraries.log

		echo "Rank, Math Library" > temp.csv
		cat mathLibraries.log | while read line; do
		f_1=$(echo $line | awk -F "." '{print $1}' | awk -F "-" '{print $2}')
		f_2=$(echo $line | awk -F "<td>" '{ print $2}' | awk -F "</td>" '{ print $1}')
		echo "$f_1, $f_2" >> temp.csv
		done
		sort -n temp.csv -o mathLibraries.csv
		rm temp.csv

		grep "Compiler:" rank-*.html > compilers.log
		sed -i '/<td><\/td>/d' compilers.log
		echo "Rank, Compilers" > temp.csv
		cat compilers.log | while read line; do
		f_1=$(echo $line | awk -F "." '{print $1}' | awk -F "-" '{print $2}')
		f_2=$(echo $line | awk -F "<td>" '{ print $2}' | awk -F "</td>" '{ print $1}')
		echo "$f_1, $f_2" >> temp.csv
		done
		sort -n temp.csv -o compilers.csv
		rm temp.csv

		grep "MPI:" rank-*.html > mpi.log
		sed -i '/<td><\/td>/d' mpi.log
		echo "Rank, MPI" > temp.csv
		cat mpi.log | while read line; do
		f_1=$(echo $line | awk -F "." '{print $1}' | awk -F "-" '{print $2}')
		f_2=$(echo $line | awk -F "<td>" '{ print $2}' | awk -F "</td>" '{ print $1}')
		echo "$f_1, $f_2" >> temp.csv
		done
		sort -n temp.csv -o mpi.csv
		rm temp.csv

		paste mathLibraries.csv compilers.csv mpi.csv > ${list_id}.csv
		
		cd ..
	done
done

