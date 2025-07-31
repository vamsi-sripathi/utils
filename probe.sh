#!/bin/bash

# set -o errexit

# to get dynamic host info, populate with nmap -sP -PS22 -PE 10.23.233.0/25
routing_prefix="10.23.233"
# host_list=($(nmap -sP -PS22 -PE 10.23.233.0/24 | grep -E 'cthor|ortce' |grep -v -E "cthor-pdu|cthor-fs" | awk -F "(" '{print $2 }' | tr -d ")"))
host_list=(ortce-knl11.jf.intel.com)
ssh_user_name=vsripath
#ssh_pub_key="$HOME/.ssh/id_rsa.pub"
ssh_opt_1="PasswordAuthentication=no"
ssh_opt_2="PreferredAuthentications=publickey"
ping_count=1

mail_file="/tmp/$(basename $0 .sh).mail"
log_file="/tmp/$(basename $0 .sh).log"
rm -f ${mail_file} ${log_file}

# create mail header
echo "To: vamsi.sripathi@intel.com"         >> ${mail_file}
# echo "Cc: ssg-drd.pae.tce.awe@intel.com"         >> ${mail_file}
echo "Subject: CTHOR Lab Machine Status"  >> ${mail_file}
echo "MIME-Version: 1.0"                    >> ${mail_file}
echo "Content-Type: multipart/mixed; boundary=BODY_BOUNDARY"  >> ${mail_file}
echo "--BODY_BOUNDARY"              >> ${mail_file}
echo "Content-Type: text/html"      >> ${mail_file}
echo "Content-Disposition: inline"  >> ${mail_file}

# create html table
echo "<html>"  >> ${mail_file}
echo "<body>"  >> ${mail_file}
echo "<br> <b> This is an auto-generated message.</b> <br>"   >> ${mail_file}
echo "<b> The table below shows the current status of CTHOR lab servers. Attached log has more diagnostic info.</b> <br><br>" >> ${mail_file}
echo "<table border="4" cellpadding="8"> <tr> <th> Hostname </th> <th> PING </th> <th> SSH </th> <th> NIS </th> <th> SYSINFO </th> </tr>" >> ${mail_file}

# loop over all hosts in subnet
for ((i=0;i<${#host_list[*]};i++))
do
	host_ip=${host_list[$i]}
	host_name=$(nslookup ${host_ip} | grep "name" | awk -F"=" '{print $2}' | sed 's/ //g')
	if [ -z "$host_name" ]; then
		host=${host_ip}
	else
		host=${host_name}
	fi;

	echo "===========================================================" >> ${log_file}
	echo "Probing host, ${host}"
	echo "Probing host, ${host}"  >> ${log_file}
	ping -c $ping_count ${host} &> /dev/null
	# continue;
	if [ $? -eq 0 ]; then
		echo "PING: PASSED" >> ${log_file}
		# timeout 10 ssh -t -t -q -o ${ssh_opt_1} -o ${ssh_opt_2} -i ${ssh_pub_key} ${ssh_user_name}@${host} <<'ENDSSH'
		timeout 10 ssh -t -t -q -o ${ssh_opt_1} -o ${ssh_opt_2} ${ssh_user_name}@${host} <<'ENDSSH'
#!/bin/bash

ping_status=PASSED
ssh_status=PASSED
mail_file=/tmp/$(whoami).mail
log_file=/tmp/$(whoami).log
rm -f ${mail_file} ${log_file}

which timeout &> /dev/null
if [ $? -eq 0 ]; then
TIMEOUT="timeout 5"
else
TIMEOUT=""
fi;

# Check NIS
nis_user_name=$(whoami)
${TIMEOUT} ypmatch $nis_user_name passwd &> /dev/null
if [ $? -eq 0 ]; then
nis_status=PASSED
echo "NIS: PASSED" >> $log_file
else
nis_status=FAILED
echo "NIS: FAILED" >> $log_file
fi;

sysinfo=$(
echo -e "
CPU     = $(cat /proc/cpuinfo | grep -m1 "model name" | awk -F ":" '{print $NF}')<br>
uArch   = $(cat /proc/cpuinfo | grep -E -m1 -w -o 'sse|sse2|sse3|ssse3|sse4_1|sse4_2|avx|fma|avx512' | tr -t '\n' ' ')<br>
Sockets = $(cat /proc/cpuinfo | grep "physical id" | sort -u | wc -l)<br>
Cores   = $(cat /proc/cpuinfo | grep "processor" | wc -l)<br>
HT      = $(siblings=$(cat /proc/cpuinfo | grep -m1 "siblings" | awk -F ":" '{print $NF}');cores=$(cat /proc/cpuinfo | grep -m1 "cpu cores" | awk -F ":" '{print $NF}'); [ "$siblings" == "$cores" ] && echo "OFF" || echo "ON")<br>
Memory  = $(cat /proc/meminfo | grep "MemTotal" | awk '{printf ("%.2f GB",$2/1000/1000)}')<br>
Intel MIC  : $(lspci | grep -c -i "co-processor")<br>
nVidia GPU : $(lspci | grep -i vga | grep -c -i "nvidia")<br>
Kernel/OS  = $(uname -r)<br>
GCC        = $(gcc -dumpversion)<br>
Uptime     = $(uptime)<br>
lsb_release = $(lsb_release -a | grep "Description:")
"
)

if [[ "$nis_status" == "PASSED" ]]; then
echo -e "<tr bgcolor="#008000"> <td>$(hostname -f)</td> <td>$ping_status</td> <td>$ssh_status</td> <td>$nis_status</td> <td>${sysinfo}</td> </tr>" > $mail_file
else
echo "<tr bgcolor="#800000"> <td>$(hostname -f)</td> <td>$ping_status</td> <td>$ssh_status</td> <td>$nis_status</td> <td>${sysinfo}</td> </tr>" > $mail_file
fi;
exit;
ENDSSH
		if [ $? -eq 0 ]; then
			scp -q -o ${ssh_opt_1} -o ${ssh_opt_2} -i ${ssh_pub_key} ${ssh_user_name}@${host}:/tmp/${ssh_user_name}.mail /tmp/$$.mail 
			scp -q -o ${ssh_opt_1} -o ${ssh_opt_2} -i ${ssh_pub_key} ${ssh_user_name}@${host}:/tmp/${ssh_user_name}.log  /tmp/$$.log
			cat /tmp/$$.mail >> ${mail_file}
			cat /tmp/$$.log  >> ${log_file}
			echo "===========================================================" >> ${log_file}
		else
			ping_status=PASSED
			ssh_status=FAILED
			nis_status=FAILED
			sysinfo_status="HOST NOT ACCESSIBLE BY SSH"
			echo "SSH: FAILED" >> ${log_file}
			echo "<tr bgcolor="#800000"> <td>$host</td> <td>$ping_status</td> <td>$ssh_status</td> <td>$nis_status</td> <td>$sysinfo_status</td> </tr>" >> ${mail_file}
			echo "===========================================================" >> ${log_file}
		fi;
	else
		echo "PING: FAILED" >> ${log_file}
		echo "===========================================================" >> ${log_file}
		ping_status=FAILED
		ssh_status=FAILED
		nis_status=FAILED
		sysinfo_status="HOST NOT ACCESSIBLE"
		echo "<tr bgcolor="#800000"> <td>$host</td> <td>$ping_status</td> <td>$ssh_status</td> <td>$nis_status</td> <td>$sysinfo_status</td> </tr>" >> ${mail_file}
	fi;
done;
echo "</table>"  >> ${mail_file}
echo "</body>"   >> ${mail_file}
echo "</html>"   >> ${mail_file}

echo "--BODY_BOUNDARY"   >> ${mail_file}
echo "Content-Type: text/plain; name=\"status_log.doc\"" >> ${mail_file}
echo "Content-Transfer-Encoding: base64" >> ${mail_file}
echo "Content-Disposition: attachment; filename=\"status_log.doc\"" >> ${mail_file}

cat ${log_file} | uuencode -m ${log_file} status_log.doc >> ${mail_file}

# send notification
cat ${mail_file} | /usr/sbin/sendmail -t

# Clean-up
# if [ $? -eq 0 ]; then
	# rm -f ${mail_file} ${log_file} /tmp/$$.mail /tmp/$$.log
# fi;
