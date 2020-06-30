#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
dev=sdc1


for dev in sdc1 #nvme1n1p1 sdc1 sde1 sdf1 ram0
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

		iozone -i 0 -r 4k -t 8 -s 100m -F /mnt/1 /mnt/2 /mnt/3 /mnt/4 /mnt/11 /mnt/22 /mnt/33 /mnt/44 -o -+n -w
		#	fio rand_update.fio #> fio_result_$i.result
		#	rm /mnt/2
		hdparm --fibmap /mnt/1 > iozonegc_hdparm_${i}_$dev.result
		/home/jonggyu/Scripts/cacheflush.sh

		#	../incur_gc.sh $dev
		#	sleep 200
		#	../off_gc.sh $dev


		iozone -i 0 -r 128k -s 100m -f /mnt/123 -+n -w
		
		for ra_size in 256 512 1024 2048
		do
			let req_size=ra_size/2
			blockdev --setra $ra_size /dev/$dev

			/home/jonggyu/Scripts/cacheflush.sh
			
			iozone -i 1 -r $req_size -s 100m -f /mnt/1 -+n -w > iozonegc_read_${i}_${dev}_${req_size}.result
			
			/home/jonggyu/Scripts/cacheflush.sh

			iozone -i 1 -r $req_size -s 100m -f /mnt/123 -+n -w > nonefrag_iozonegc_read_${i}_${dev}_${req_size}.result

		done
		#	hdparm --fibmap /mnt/1 > iozonegc_hdparm_${i}_after.result
		
		/home/jonggyu/Scripts/cacheflush.sh

		if [ "$dev" == "sdc1" ]; then
			fstrim -v /mnt/
			rm /mnt/1
			time (fstrim -v /dev/) &> trim_elapsed_time_$dev.result
			rm /mnt/123
			time (fstrim -v /dev/) &> nonefrag_trim_elapsed_time_$dev.result


		fi
		umount /dev/$dev

	done
done
