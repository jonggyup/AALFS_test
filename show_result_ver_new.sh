#!/bin/bash

array=(before_gc.frag after_gc.frag before_read.result after_read.result before_select.result after_select.result)
#trim_time.result


printf "%-15s" "SSD    "
for i in "${array[@]}"
do
	tmp=$(echo $i | cut -d. -f 1)
	printf "%-6s%2s  " "$tmp"
done
printf "\n"

for ra_size in 8 16 32 64 128 256 512 1024 2048
do
	let req_size=ra_size/2
	for j in 1 2 4 8 16 32
	do

		base_dir=/home/jonggyu/frag_test/sqlite_exp_again/ongoing/SDcard/$j
		tmp=SSD_${req_size}_sec_$j
		printf "%-15s " "$tmp"


		for i in "${array[@]}"
		do
			var1=$(echo $i | cut -d. -f2)
			if [ "$var1" == "frag" ]; then	
				value=$(wc -l $base_dir/$i | awk '{print $1}')
			else
				tmp1=$(echo $i | cut -d. -f 1)
				#echo $tmp1
				value=$(cat $base_dir/${tmp1}_${ra_size}.result | sed -n 15p | awk '{print $1}')

			fi
			printf "%-8.6s%6s" "$value" "  |  "

		done

		printf "\n"
	done
done
