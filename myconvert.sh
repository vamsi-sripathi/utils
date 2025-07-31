#!/bin/bash

if [[ -z "$1" || "$1" == "help" ]]; then
	echo "This script takes input a single *.eps file or path to a directory containing *.eps files."
	echo "The purpose is to convert eps --> png with these options (density 300 -flatten -rotate 90)" 
	echo "Usage: $0 [eps filename (or) path to directory containing eps files]"
	exit
fi

if [ -d "$1" ]; then
# To convert a directory full of *.eps files
	for i in `ls $1/*.eps`
	do
		echo "Converting $i to ${i%.eps}.png"
		convert -density 300 -flatten -rotate 90 $i ${i%.eps}.png
	done	
else	
# To convert a single *.eps file
	echo "Converting $1 to ${1%.eps}.png"
	convert -density 300 -flatten -rotate 90 $1 ${1%.eps}.png
fi	
