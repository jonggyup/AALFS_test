#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
startbase_dir=/home/jonggyu/frag_test/iozone_exp_again/ongoing

for dev in sde1 #sdf1 #sdc1 nvme1n1p1
do
	case $dev in
		nvme1n1p1)
			size=1g
			base_dir=$startbase_dir/NVMe
			;;
		sdc1)
			size=400m
			base_dir=$startbase_dir/SSD
			;;
		sde1)
			size=100m
			base_dir=$startbase_dir/HDD
			;;
		sdf1)
			size=50m
			base_dir=$startbase_dir/SDcard
			;;

		esac
		mkdir $base_dir


		for i in 1 2 4 8 16 32
		do
			umount /mnt
			/home/jonggyu/mount.sh /dev/$dev /mnt $i
			mkdir $base_dir/$i
			result_path=$base_dir/$i

			/home/jonggyu/Research/Benchmarks/ACCESS20/disable_gc.sh $dev

			iozone -i 0 -t 32 -I -r 4k -s $size -F /mnt/1 /mnt/2 /mnt/3 /mnt/4 /mnt/5 /mnt/6 /mnt/7 /mnt/8 /mnt/111 /mnt/222 /mnt/333 /mnt/444 /mnt/555 /mnt/666 /mnt/777 /mnt/888 /mnt/10 /mnt/20 /mnt/30 /mnt/40 /mnt/50 /mnt/60 /mnt/70 /mnt/80 /mnt/1110 /mnt/2220 /mnt/3330 /mnt/4440 /mnt/5550 /mnt/6660 /mnt/7770 /mnt/8880 -w -+n

			hdparm --fibmap /mnt/1 > $result_path/before_gc.frag


			iozone -i 0 -t 4 -I -r 4k -s 1m -F /mnt/11 /mnt/22 /mnt/33 /mnt/44 -w -+n

			ls -alh /mnt/ > $result_path/ls.result
			
			/home/jonggyu/Scripts/cacheflush.sh

			for ra_size in 8 16 32 64 128 256 512 1024 2048
			do
				blockdev --setra $ra_size /dev/$dev
				let req_size=ra_size/2

				/home/jonggyu/Scripts/cacheflush.sh

				iozone -i 1 -r ${req_size}k -s $size -f /mnt/1 -w -+n > $result_path/before_read_${ra_size}.result

				/home/jonggyu/Scripts/cacheflush.sh

				(perf stat grep -r "asdf" /mnt/1) &> $result_path/before_grep_${ra_size}.result

			done

			fstrim /mnt

			rm /mnt/2
	
			(perf stat fstrim /mnt) &> $result_path/trim_time_bf.result

			#Remove the file fio generates
			rm /mnt/22 /mnt/3 /mnt/4 /mnt/6 /mnt/8 /mnt/111 /mnt/333 /mnt/444 /mnt/555 /mnt/777 /mnt/10 /mnt/30 /mnt/40 /mnt/50 /mnt/60 /mnt/70 /mnt/1110 /mnt/2220 /mnt/3330 /mnt/4440 /mnt/5550 /mnt/8880 /mnt/5 /mnt/7 /mnt/666 /mnt/888 /mnt/80 /mnt/7770

			#Flush the page cache
			/home/jonggyu/Scripts/cacheflush.sh
			ls /mnt
			#Perform grep and measure the time
	
			wait

			echo "GC Start" > /dev/kmsg

			/home/jonggyu/Research/Benchmarks/ACCESS20/incur_gc.sh $dev

			sleep 600

			/home/jonggyu/Research/Benchmarks/ACCESS20/off_gc.sh $dev

			echo "GC Finished" > /dev/kmsg

			cat /sys/kernel/debug/f2fs/status > $result_path/f2fs_status.txt

			

			sleep 60

			/home/jonggyu/Scripts/cacheflush.sh

			hdparm --fibmap /mnt/1 > $result_path/after_gc.frag
			
			wait

			for ra_size in 8 16 32 64 128 256 512 1024 2048
			do
					
				echo "Read Start" > /dev/kmsg
				blockdev --setra $ra_size /dev/$dev
				let req_size=ra_size/2

				/home/jonggyu/Scripts/cacheflush.sh

				iozone -i 1 -r ${req_size}k -s $size -f /mnt/1 -w -+n > $result_path/after_read_${ra_size}.result

				/home/jonggyu/Scripts/cacheflush.sh

				(perf stat grep -r "asdf" /mnt/1) &> $result_path/after_grep_${ra_size}.result

			done


			fstrim /mnt

			rm /mnt/1

			(perf stat fstrim /mnt) &> $result_path/trim_time_af.result
		done
		yes | mkfs.ext4 /dev/$dev
	done
