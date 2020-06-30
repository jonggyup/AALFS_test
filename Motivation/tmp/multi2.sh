#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
dev=sdc1


for dev in nvme1n1p1 sdc1 sde1 sdf1 ram0
do
	for i in f2fs #ext4 f2fs btrfs
	do
		umount /mnt
		if [ "$i" == "ext4" ]; then
			yes | mkfs.ext4 /dev/sdc1
		else 
			mkfs.f2fs /dev/$dev -f
		fi

		mount /dev/$dev /mnt -o background_gc=sync


		iozone -i 0 -r 128k -s 100m -f /mnt/123 -+n -w
		
		for ra_size in 8 16 32 64 128 256 512 1024 2048
		do
			let req_size=ra_size/2
			blockdev --setra $ra_size /dev/$dev

			/home/jonggyu/Scripts/cacheflush.sh
			
			iozone -i 1 -r $req_size -s 100m -f /mnt/123 -+n -w > nonefrag_iozonegc_read_${i}_${dev}_${req_size}.result

		done
		#	hdparm --fibmap /mnt/1 > iozonegc_hdparm_${i}_after.result
		
		/home/jonggyu/Scripts/cacheflush.sh

		umount /dev/$dev

	done
done
