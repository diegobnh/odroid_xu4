#!/bin/bash

#You need to be sudo to execute this script

#Setup freq to maximum

for i in 0 1 2 3 4 5 6 7  
do
  echo performance > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor;
done

make

rm -f -- *.csv *.energy

SUIT_NAME="4l_rodinia_"

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/rodinia/openmp/backprop/backprop 10000000
mkdir $SUIT_NAME"backprop"; mv *.csv *.energy $SUIT_NAME"backprop"; tar -cf $SUIT_NAME"backprop.tar" $SUIT_NAME"backprop";
rm -r $SUIT_NAME"backprop"; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/rodinia/openmp/heartwall/heartwall /home/odroid/workloads/rodinia/data/heartwall/test.avi.part00 54
mkdir $SUIT_NAME"heartwall"; mv *.csv *.energy $SUIT_NAME"heartwall"; tar -cf $SUIT_NAME"heartwall.tar" $SUIT_NAME"heartwall";
rm -r $SUIT_NAME"heartwall"; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/rodinia/openmp/lavaMD/lavaMD -boxes1d 20
mkdir $SUIT_NAME"lavaMD"; mv *.csv *.energy $SUIT_NAME"lavaMD"; tar -cf $SUIT_NAME"lavaMD.tar" $SUIT_NAME"lavaMD"
rm -r $SUIT_NAME"lavaMD"; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/rodinia/openmp/particlefilter/./particle_filter -x 512 -y 512 -z 40 -np 40000
mkdir $SUIT_NAME"particlefilter"; mv *.csv *.energy $SUIT_NAME"particlefilter"; tar -cf $SUIT_NAME"particlefilter.tar" $SUIT_NAME"particlefilter"
rm -r $SUIT_NAME"particlefilter"; sleep 3;


SUIT_NAME="4b4l_A7_rodinia_"


taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/rodinia/openmp/backprop/backprop 10000000
mkdir $SUIT_NAME"backprop"; mv *.csv *.energy $SUIT_NAME"backprop"; tar -cf $SUIT_NAME"backprop.tar" $SUIT_NAME"backprop";
rm -r $SUIT_NAME"backprop"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/rodinia/openmp/heartwall/heartwall /home/odroid/workloads/rodinia/data/heartwall/test.avi.part00 54
mkdir $SUIT_NAME"heartwall"; mv *.csv *.energy $SUIT_NAME"heartwall"; tar -cf $SUIT_NAME"heartwall.tar" $SUIT_NAME"heartwall";
rm -r $SUIT_NAME"heartwall"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/rodinia/openmp/lavaMD/lavaMD -boxes1d 20
mkdir $SUIT_NAME"lavaMD"; mv *.csv *.energy $SUIT_NAME"lavaMD"; tar -cf $SUIT_NAME"lavaMD.tar" $SUIT_NAME"lavaMD"
rm -r $SUIT_NAME"lavaMD"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/rodinia/openmp/particlefilter/./particle_filter -x 512 -y 512 -z 40 -np 40000
mkdir $SUIT_NAME"particlefilter"; mv *.csv *.energy $SUIT_NAME"particlefilter"; tar -cf $SUIT_NAME"particlefilter.tar" $SUIT_NAME"particlefilter"
rm -r $SUIT_NAME"particlefilter"; sleep 3;




SUIT_NAME="4b_rodinia_"

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/rodinia/openmp/backprop/backprop 10000000
mkdir $SUIT_NAME"backprop"; mv *.csv *.energy $SUIT_NAME"backprop"; tar -cf $SUIT_NAME"backprop.tar" $SUIT_NAME"backprop";
rm -r $SUIT_NAME"backprop"; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/rodinia/openmp/heartwall/heartwall /home/odroid/workloads/rodinia/data/heartwall/test.avi.part00 54
mkdir $SUIT_NAME"heartwall"; mv *.csv *.energy $SUIT_NAME"heartwall"; tar -cf $SUIT_NAME"heartwall.tar" $SUIT_NAME"heartwall";
rm -r $SUIT_NAME"heartwall"; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/rodinia/openmp/lavaMD/lavaMD -boxes1d 20
mkdir $SUIT_NAME"lavaMD"; mv *.csv *.energy $SUIT_NAME"lavaMD"; tar -cf $SUIT_NAME"lavaMD.tar" $SUIT_NAME"lavaMD"
rm -r $SUIT_NAME"lavaMD"; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/rodinia/openmp/particlefilter/./particle_filter -x 512 -y 512 -z 40 -np 40000
mkdir $SUIT_NAME"particlefilter"; mv *.csv *.energy $SUIT_NAME"particlefilter"; tar -cf $SUIT_NAME"particlefilter.tar" $SUIT_NAME"particlefilter"
rm -r $SUIT_NAME"particlefilter"; sleep 3;



SUIT_NAME="4b4l_A15_rodinia_"

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/rodinia/openmp/backprop/backprop 10000000
mkdir $SUIT_NAME"backprop"; mv *.csv *.energy $SUIT_NAME"backprop"; tar -cf $SUIT_NAME"backprop.tar" $SUIT_NAME"backprop";
rm -r $SUIT_NAME"backprop"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/rodinia/openmp/heartwall/heartwall /home/odroid/workloads/rodinia/data/heartwall/test.avi.part00 54
mkdir $SUIT_NAME"heartwall"; mv *.csv *.energy $SUIT_NAME"heartwall"; tar -cf $SUIT_NAME"heartwall.tar" $SUIT_NAME"heartwall";
rm -r $SUIT_NAME"heartwall"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/rodinia/openmp/lavaMD/lavaMD -boxes1d 20
mkdir $SUIT_NAME"lavaMD"; mv *.csv *.energy $SUIT_NAME"lavaMD"; tar -cf $SUIT_NAME"lavaMD.tar" $SUIT_NAME"lavaMD"
rm -r $SUIT_NAME"lavaMD"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 *.energy /home/odroid/workloads/rodinia/openmp/particlefilter/./particle_filter -x 512 -y 512 -z 40 -np 40000
mkdir $SUIT_NAME"particlefilter"; mv *.csv *.energy $SUIT_NAME"particlefilter"; tar -cf $SUIT_NAME"particlefilter.tar" $SUIT_NAME"particlefilter"
rm -r $SUIT_NAME"particlefilter"; sleep 3;

