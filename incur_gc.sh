#!/bin/bash

echo 2 > /sys/fs/f2fs/$1/gc_min_sleep_time

echo 2 > /sys/fs/f2fs/$1/gc_max_sleep_time


echo 10 > /sys/fs/f2fs/$1/cp_interval


echo 2 > /sys/fs/f2fs/$1/gc_no_gc_sleep_time

echo "Successfully incur cleaning"
