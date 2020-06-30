#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
dev=sdc1


for dev in nvme1n1p1 sdc1 sde1 sdf1 ram0p1
do
	frag=$(cat ./iozonegc_read_f2fs_${dev}.result | tail -3 | head -1 | awk '{print $3}')
	nonfrag=$(cat ./nonefrag_iozonegc_read_f2fs_${dev}.result | tail -3 | head -1 | awk '{print $3}')

	echo $dev "  clean = " $nonfrag "  frag = " $frag

done
