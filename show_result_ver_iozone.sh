#!/bin/bash

array=(before_gc.frag after_gc.frag before_read.result after_read.result trim_time_bf.result trim_time_af.result)


printf "%-15s" "SSD    "
for i in "${array[@]}"
do
tmp=$(echo $i | cut -d. -f 1)
printf "%-6s%2s  " "$tmp"
done
printf "\n"

for ra_size in 256 512 1024 2048
do
	base_dir=/home/jonggyu/frag_test/iozone_exp/ongoing/$1/$1_$ra_size

for j in 1 2 4 8 16 32
do
tmp=HDD_${ra_size}_sec_$j
printf "%-15s " "$tmp"


for i in "${array[@]}"
do


var1=$(echo $i | cut -d. -f2)
if [ "$var1" == "frag" ]; then	
	value=$(wc -l $base_dir/$j/$i | awk '{print $1}')
else
	value=$(cat $base_dir/$j/$i | tail -3 | head -1 | awk '{print $3}')
fi
	printf "%-8.6s%6s" "$value" "  |  "
	
done

printf "\n"
done
done
