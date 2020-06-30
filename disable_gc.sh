#!/bin/bash

echo 300000 > /sys/fs/f2fs/$1/gc_min_sleep_time

echo 600000 > /sys/fs/f2fs/$1/gc_max_sleep_time


echo 60 > /sys/fs/f2fs/$1/cp_interval


echo 3000000 > /sys/fs/f2fs/$1/gc_no_gc_sleep_time


