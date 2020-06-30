#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
#dev=sdc1
startbase_dir=/home/jonggyu/frag_test/sqlite_exp_again/ongoing

for dev in sdc1 #nvme1n1p1 #sdc1 sde1 sdf1
do
	case $dev in
		nvme1n1p1)
			querynum=100000000
			fiofile=tmp_nvme
			base_dir=$startbase_dir/NVMe
			;;
		sdc1)
			querynum=30000000
			fiofile=tmp_ssd
			base_dir=$startbase_dir/SSD
			;;
		sdf1)
			querynum=4500000
			fiofile=tmp_sd
			base_dir=$startbase_dir/SDcard
			;;
		sde1)
			querynum=3000000
			fiofile=tmp_hdd
			base_dir=$startbase_dir/HDD
			;;

	esac
	mkdir $base_dir

		for i in 1 2 4 8 16 32
		do
			umount /mnt
			umount /dev/$dev
			#Mount /dev/sdc1 to /mnt
			/home/jonggyu/mount.sh /dev/$dev /mnt $i
			mkdir $base_dir/$i
			result_path=$base_dir/$i
			
			/home/jonggyu/Research/Benchmakrs/ACCESS20/disable_gc.sh $dev
			#	/home/jonggyu/Research/Benchmarks/ACCESS20/disable_gc.sh $dev

			#Run seq write with 4KB Direct IO
			fio $fiofile.fio &
			thread1=$!
			fio ${fiofile}2.fio &
			thread2=$!

			sleep 2
			#Run sqlite the insert workload
			(time /home/jonggyu/Research/Benchmarks/sqlite-bench/sqlite-bench --benchmarks=fillseqsync --use_existing_db=0 --db=/mnt/ --value_size=1024 --num=$querynum --WAL_enabled=0) &> $result_path/sqlite_elapsedTime.txt

			kill $thread1
			kill $thread2

			sleep 30
			wait 

			ls -alh /mnt/ > $result_path/ls.result

			#Remove the file fio generates
#			rm /mnt/file.db
			rm /mnt/hole.db

			#Flush the page cache
			/home/jonggyu/Scripts/cacheflush.sh

			sleep 5

			#Measure the fragmentation of the sqlite db file 
			hdparm --fibmap /mnt/dbbench_sqlite3-2.db > $result_path/before_gc.frag

			for ra_size in 8 16 32 64 128 256 512 1024 2048
			do
				blockdev --setra $ra_size /dev/$dev

				/home/jonggyu/Scripts/cacheflush.sh

				#Perform grep and measure the time
				(perf stat grep -r "asdf" /mnt/dbbench_sqlite3-2.db) &> $result_path/before_read_$ra_size.result

				/home/jonggyu/Scripts/cacheflush.sh

				(perf stat sqlite3 /mnt/dbbench_sqlite3-2.db "SELECT * from test" >/dev/null) &> $result_path/before_select_$ra_size.result
			done

			fstrim -v /mnt
			#Flush the page cache
			/home/jonggyu/Scripts/cacheflush.sh
			
			wait
			sleep 30
			
			echo "GC Start" > /dev/kmsg
			/home/jonggyu/Research/Benchmarks/ACCESS20/incur_gc.sh $dev

			sleep 1000

			/home/jonggyu/Research/Benchmarks/ACCESS20/off_gc.sh $dev

			echo "GC Finished" > /dev/kmsg

			cat /sys/kernel/debug/f2fs/status > $result_path/f2fs_status.txt

			/home/jonggyu/Scripts/cacheflush.sh

			wait 

			sleep 30

			for ra_size in 8 16 32 64 128 256 512 1024 2048
			do
				blockdev --setra $ra_size /dev/$dev

				/home/jonggyu/Scripts/cacheflush.sh

				#Perform grep and measure the time
				(perf stat grep -r "asdf" /mnt/dbbench_sqlite3-2.db) &> $result_path/after_read_$ra_size.result

				/home/jonggyu/Scripts/cacheflush.sh

				(perf stat sqlite3 /mnt/dbbench_sqlite3-2.db "SELECT * from test" >/dev/null) &> $result_path/after_select_$ra_size.result
			done


			hdparm --fibmap /mnt/dbbench_sqlite3-2.db > $result_path/after_gc.frag

			fstrim /mnt

			rm /mnt/dbbench_sqlite3-2.db

			(perf stat fstrim /mnt) &> $result_path/trim_time.result
		done
	done
