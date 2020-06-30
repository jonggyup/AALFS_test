#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
dev=sdc1


for dev in nvme1n1p1 sdc1 sde1 sdf1 ram0
do
	for size in 4 8 16 32 64 128 256 512 1024
	do
#	frag=$(cat ./iozonegc_read_f2fs_${dev}_${size}.result | tail -3 | head -1 | awk '{print $3}')
	nonfrag=$(cat ./nonefrag_iozonegc_read_f2fs_${dev}_${size}.result | tail -3 | head -1 | awk '{print $3}')

	echo $dev $size  "  clean = " $nonfrag #"  frag = " $frag
	done
done
