#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
dev=sdc1
base_dir=/home/jonggyu/frag_test/sqlite_exp_final/ongoing/SSD
mkdir $base_dir


for i in 1 2 4 8 16 32
do
	umount /mnt
	#Mount /dev/sdc1 to /mnt
	/home/jonggyu/mount.sh /dev/$dev /mnt $i
	mkdir $base_dir/$i
	result_path=$base_dir/$i

	#	/home/jonggyu/Research/Benchmarks/ACCESS20/disable_gc.sh $dev

	#Run seq write with 4KB Direct IO
	fio /home/jonggyu/Research/Benchmarks/ACCESS20/tmp.fio &

	#Run sqlite the insert workload
	(time /home/jonggyu/Research/Benchmarks/sqlite-bench/sqlite-bench --benchmarks=fillseqsync --use_existing_db=0 --db=/mnt/ --value_size=1024 --num=30000000 --WAL_enabled=0) &> $result_path/sqlite_elapsedTime.txt

	kill $!

	sleep 60

	ls -alh /mnt/ > $result_path/ls.result

	#Remove the file fio generates
	rm /mnt/file.db

	#Flush the page cache
	/home/jonggyu/Scripts/cacheflush.sh

	sleep 5

	#Measure the fragmentation of the sqlite db file 
	hdparm --fibmap /mnt/dbbench_sqlite3-2.db > $result_path/before_gc.frag

	for ra_size in 256 512 1024 2048
	do
		blockdev --setra $ra_size /dev/$dev

		/home/jonggyu/Scripts/cacheflush.sh

		#Perform grep and measure the time
		(perf stat grep -r "asdf" /mnt/) &> $result_path/before_read_$ra_size.result

		/home/jonggyu/Scripts/cacheflush.sh

		(perf stat sqlite3 /mnt/dbbench_sqlite3-2.db "SELECT * from test" >/dev/null) &> $result_path/before_select_$ra_size.result
	done
	#Flush the page cache
	/home/jonggyu/Scripts/cacheflush.sh

	/home/jonggyu/Research/Benchmarks/ACCESS20/incur_gc.sh $dev

	sleep 600

	/home/jonggyu/Research/Benchmarks/ACCESS20/off_gc.sh $dev

	cat /sys/kernel/debug/f2fs/status > $result_path/f2fs_status.txt

	/home/jonggyu/Scripts/cacheflush.sh

	sleep 30

	for ra_size in 256 512 1024 2048
	do
		blockdev --setra $ra_size /dev/$dev

		/home/jonggyu/Scripts/cacheflush.sh

		#Perform grep and measure the time
		(perf stat grep -r "asdf" /mnt/) &> $result_path/after_read_$ra_size.result

		/home/jonggyu/Scripts/cacheflush.sh

		(perf stat sqlite3 /mnt/dbbench_sqlite3-2.db "SELECT * from test" >/dev/null) &> $result_path/after_select_$ra_size.result
	done


	hdparm --fibmap /mnt/dbbench_sqlite3-2.db > $result_path/after_gc.frag

	fstrim /mnt

	rm /mnt/*

	(perf stat fstrim /mnt) &> $result_path/trim_time.result
done
