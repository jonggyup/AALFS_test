#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
dev=nvme1n1p1
base_dir=/home/jonggyu/frag_test/oltp/ongoing/NVMe
mkdir $base_dir

for i in 32 #1 2 4 8 16 32
do
	umount /mnt
	/home/jonggyu/mount.sh /dev/$dev /mnt $i
	result_path=$base_dir/$i
	mkdir $result_path
#	/home/jonggyu/Research/Benchmarks/ACCESS20/disable_gc.sh $dev

	#Run seq write with 4KB Direct IO
	fio /home/jonggyu/Research/Benchmarks/ACCESS20/tmp.fio &

	#Run sqlite the insert workload
	filebench -f /home/jonggyu/oltp.f

	sleep 60

	du -h /mnt/datafiles > $result_path/size.result
	

	#Remove the file fio generates
	rm /mnt/file.db

	/home/jonggyu/Scripts/measure_frag.pl /mnt/datafiles > $result_path/before_frag.result
	
	#Flush the page cache
	/home/jonggyu/Scripts/cacheflush.sh

	sleep 5
	for ra_size in 256 512 1024 2048
	do
		blockdev --setra $ra_size /dev/$dev


		#Perform grep and measure the time
		(perf stat grep -r "asdf" /mnt/datafiles) &> $result_path/before_read_$ra_size.result
		/home/jonggyu/Scripts/cacheflush.sh
	done

	/home/jonggyu/Research/Benchmarks/ACCESS20/incur_gc.sh $dev

	sleep 600

	/home/jonggyu/Research/Benchmarks/ACCESS20/off_gc.sh $dev

	cat /sys/kernel/debug/f2fs/status > $result_path/f2fs_status.txt

	/home/jonggyu/Scripts/measure_frag.pl /mnt/datafiles > $result_path/after_frag.result

	/home/jonggyu/Scripts/cacheflush.sh

	sleep 30
	for ra_size in 256 512 1024 2048
	do
		blockdev --setra $ra_size /dev/$dev


		#Perform grep and measure the time
		(perf stat grep -r "asdf" /mnt/datafiles) &> $result_path/after_read_$ra_size.result
		/home/jonggyu/Scripts/cacheflush.sh
	done
	
	rm /mnt/logfile -rf

	fstrim /mnt

	rm /mnt/* -rf

	(perf stat fstrim /mnt) &> $result_path/trim_time.result
done
