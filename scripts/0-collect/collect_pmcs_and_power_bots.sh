#!/bin/bash

#You need to be sudo to execute this script

#Setup freq to maximum

for i in 0 1 2 3 4 5 6 7  
do
  echo performance > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor;
done

make

rm -f -- *.csv *.energy

SUIT_NAME=("4l_bots_" "4b4l_A7_bots_" "4b_bots_" "4b4l_A15_bots_")
CPU_LIST=("0-3" "0-7" "4-7" "0-7")
CPU_CORE=("scheduler_A7" "scheduler_A7" "scheduler_A15" "scheduler_A15")  

for ((j = 0; j < ${#SUIT_NAME[@]}; j++)); do
        taskset -a -c ${CPU_LIST[$j]} ./bin/${CPU_CORE[$j]} /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 32
        mkdir ${SUIT_NAME[$j]}"fib"; mv *.csv *.energy  ${SUIT_NAME[$j]}"fib"; tar -cf ${SUIT_NAME[$j]}"fib.tar" ${SUIT_NAME[$j]}"fib";
        rm -r ${SUIT_NAME[$j]}"fib"; sleep 3;

        taskset -a -c ${CPU_LIST[$j]} ./bin/${CPU_CORE[$j]} /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 12
        mkdir ${SUIT_NAME[$j]}"nqueens"; mv *.csv *.energy  ${SUIT_NAME[$j]}"nqueens"; tar -cf ${SUIT_NAME[$j]}"nqueens.tar" ${SUIT_NAME[$j]}"nqueens";
        rm -r ${SUIT_NAME[$j]}"nqueens"; sleep 3;

        taskset -a -c ${CPU_LIST[$j]} ./bin/${CPU_CORE[$j]} /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input
        mkdir ${SUIT_NAME[$j]}"health"; mv *.csv *.energy  ${SUIT_NAME[$j]}"health"; tar -cf ${SUIT_NAME[$j]}"health.tar" ${SUIT_NAME[$j]}"health"
        rm -r ${SUIT_NAME[$j]}"health"; sleep 3;

        taskset -a -c ${CPU_LIST[$j]} ./bin/${CPU_CORE[$j]} /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.15
        mkdir ${SUIT_NAME[$j]}"floorplan"; mv *.csv *.energy  ${SUIT_NAME[$j]}"floorplan"; tar -cf ${SUIT_NAME[$j]}"floorplan.tar" ${SUIT_NAME[$j]}"floorplan"
        rm -r ${SUIT_NAME[$j]}"floorplan"; sleep 3;

        taskset -a -c ${CPU_LIST[$j]} ./bin/${CPU_CORE[$j]} /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 1000000
        mkdir ${SUIT_NAME[$j]}"fft" ; mv *.csv *.energy  ${SUIT_NAME[$j]}"fft"; tar -cf ${SUIT_NAME[$j]}"fft.tar" ${SUIT_NAME[$j]}"fft"
        rm -r ${SUIT_NAME[$j]}"fft" ; sleep 3;

        taskset -a -c ${CPU_LIST[$j]} ./bin/${CPU_CORE[$j]} /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000
        mkdir ${SUIT_NAME[$j]}"sort"; mv *.csv *.energy  ${SUIT_NAME[$j]}"sort" ; tar -cf ${SUIT_NAME[$j]}"sort.tar" ${SUIT_NAME[$j]}"sort"
        rm -r ${SUIT_NAME[$j]}"sort" ; sleep 3;

        taskset -a -c ${CPU_LIST[$j]} ./bin/${CPU_CORE[$j]} /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 75 -m 75
        mkdir ${SUIT_NAME[$j]}"sparselu" ; mv *.csv *.energy  ${SUIT_NAME[$j]}"sparselu" ; tar -cf ${SUIT_NAME[$j]}"sparselu.tar" ${SUIT_NAME[$j]}"sparselu"
        rm -r ${SUIT_NAME[$j]}"sparselu" ; sleep 3;

        taskset -a -c ${CPU_LIST[$j]} ./bin/${CPU_CORE[$j]} /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096
        mkdir ${SUIT_NAME[$j]}"strassen" ; mv *.csv *.energy  ${SUIT_NAME[$j]}"strassen" ; tar -cf ${SUIT_NAME[$j]}"strassen.tar" ${SUIT_NAME[$j]}"strassen"
        rm -r ${SUIT_NAME[$j]}"strassen" ; sleep 3;

done

