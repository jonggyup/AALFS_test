#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
#dev=sdc1
startbase_dir=/home/jonggyu/frag_test/sqlite_exp_again/ongoing

fio tmp_sd.fio &
thread1=$!
fio tmp_sd2.fio &
thread2=$!
sleep 4
kill -9 $thread1
kill -9 $thread2
