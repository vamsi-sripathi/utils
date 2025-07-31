#!/usr/bin/python
#===============================================================================
# Copyright 2016 Intel Corporation All Rights Reserved.
#
# The source code,  information  and material  ("Material") contained  herein is
# owned by Intel Corporation or its  suppliers or licensors,  and  title to such
# Material remains with Intel  Corporation or its  suppliers or  licensors.  The
# Material  contains  proprietary  information  of  Intel or  its suppliers  and
# licensors.  The Material is protected by  worldwide copyright  laws and treaty
# provisions.  No part  of  the  Material   may  be  used,  copied,  reproduced,
# modified, published,  uploaded, posted, transmitted,  distributed or disclosed
# in any way without Intel's prior express written permission.  No license under
# any patent,  copyright or other  intellectual property rights  in the Material
# is granted to  or  conferred  upon  you,  either   expressly,  by implication,
# inducement,  estoppel  or  otherwise.  Any  license   under such  intellectual
# property rights must be express and approved by Intel in writing.
#
# Unless otherwise agreed by Intel in writing,  you may not remove or alter this
# notice or  any  other  notice   embedded  in  Materials  by  Intel  or Intel's
# suppliers or licensors in any way.
#===============================================================================

#tr -cd '\11\12\15\40-\176' < mkl.out > mkl_clean.out
import argparse
import re
import operator
from collections import defaultdict

def read_args():
	parser = argparse.ArgumentParser(description='Summarize Intel(R) Math Kernel Library (MKL) verbose mode output')
	parser.add_argument("in_file", help="Input file containing Intel(R) MKL verbose output")
	return (parser.parse_args())

def read_from_file(ifp):
	return (re.findall("MKL_VERBOSE.*",ifp.read()))

def get_fnames(funcs):
	return ([i.split('(',1)[0] for i in funcs])

def populate_list(ibuff, funcs, time):
	words = []
	for i in range (1,len(ibuff)):
		words = ibuff[i].split()
		funcs.append(words[1])
		time.append(words[2])
	
	for i in range(0,len(time)):
		temp = re.findall("[-+]?\d+[\.]?\d*", time[i])
		if (re.match(".*ms",time[i])):
			time[i] = float(temp[0])/1E3
		elif (re.match(".*us",time[i])):
			time[i] = float(temp[0])/1E6
		elif (re.match(".*ns",time[i])):
			time[i] = float(temp[0])/1E9
		else:
			time[i] = float(temp[0])

def get_tot_time(time):
	return (sum(float(i) for i in time))

def get_f_dict(fnames, time):
	f_dict = defaultdict(lambda: (0.0,0))
	for i in range(len(fnames)):
		t, c = f_dict[fnames[i]]
		f_dict[fnames[i]] = (t + time[i], c + 1)
	return f_dict

def get_fg_dict(funcs, time):
	fg_dict = defaultdict(lambda: (0.0,0))
	for i in range(len(funcs)):
		key = re.sub("0x[a-z0-9]*[,]","",funcs[i])
		key = re.sub(",","_",key)
		key = re.sub("\(","_",key)
		key = re.sub("\)","",key)
		t, c = fg_dict[key]
		fg_dict[key] = (t + time[i], c + 1)
	return fg_dict

def print_mkl_info(ibuff):
	temp = re.sub("MKL_VERBOSE","",ibuff[0])
	temp = re.split(",",temp)
	print "------------------------------------------------------------------------------------"
	print "Intel(R) MKL version, Interface and Threading layers, targeted CPU, OS, Platform info :"
	print "------------------------------------------------------------------------------------"
	for i in temp:
		print i

def print_f_dict(sorted_f_dict, f_dict, tot_time):
	print "\nBreak-down of MKL functions :"
	print "--------------------------------------------------------"
	print "{:<15s} {:<15s} {:<15s} {:<15s}".format("MKL_FUNCTION", "COUNT", "TIME(sec)", "% of MKL")
	print "--------------------------------------------------------"

	for k in sorted_f_dict:
		print "{:<15s}  {:<15d}  {:<15.2E}  {:<15.2f}".format(k[0],f_dict[k[0]][1], k[1][0], (k[1][0]/tot_time)*100)

def print_fg_dict(sorted_fg_dict, fg_dict, tot_time):
	print "\nBreak-down of MKL functions (grouped by sets of same function parameters) :"
	print "------------------------------------------------------------------------------------------------------"
	print "{:<20s} {:<40s} {:<15s} {:<15s} {:<15s}".format("MKL_FUNCTION", "ARGUMENTS", "COUNT", "TIME(sec)", "% of MKL")
	print "------------------------------------------------------------------------------------------------------"

	for k in sorted_fg_dict:
		f = re.split("_",k[0])
		a = " ".join(map(str,f[1:]))
		print "{:<20s} {:<40s} {:<15d} {:<15.2E}  {:<15.2f}".format(f[0], a, fg_dict[k[0]][1], k[1][0], (k[1][0]/tot_time)*100)

if __name__ == "__main__":
	funcs = []
	time  = []

	args  = read_args()
	ifp   = open(args.in_file, 'r')
	ibuff = read_from_file(ifp)
	populate_list(ibuff, funcs, time)

	fnames   = get_fnames(funcs)
	f_dict   = get_f_dict(fnames, time)
	fg_dict  = get_fg_dict(funcs, time)
	tot_time = get_tot_time(time)

	sorted_f_dict = sorted(f_dict.items(), key=operator.itemgetter(1),reverse=True)
	sorted_fg_dict = sorted(fg_dict.items(), key=operator.itemgetter(1),reverse=True)

	print_mkl_info(ibuff)
	print_f_dict(sorted_f_dict, f_dict, tot_time)
	print_fg_dict(sorted_fg_dict, fg_dict, tot_time)

	print "\n\nTotal number of MKL function executed  = {:d}".format(len(fnames))
	print "Total time spent in MKL functions      = {:.2E} sec (Hint: Use this to find the % of MKL time in the app)\n".format(tot_time)

	ifp.close()
