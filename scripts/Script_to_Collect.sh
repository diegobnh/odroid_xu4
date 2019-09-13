#!/bin/bash

#You need to be sudo to execute this script

#Setup freq to maximum

for i in 0 1 2 3 4 5 6 7  
do
  echo performance > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor;
done

#Define FLAG PMCS_A7_ONLY in perf.hpp and execute make


SUIT_NAME="4l_bots_"

taskset -a -c 0-3 ./bin/scheduler /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36
tar -cf $SUIT_NAME"fib.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-3 ./bin/scheduler /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13
tar -cf $SUIT_NAME"nqueens.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-3 ./bin/scheduler /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input
tar -cf $SUIT_NAME"health.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-3 ./bin/scheduler /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20
tar -cf $SUIT_NAME"floorplan.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-3 ./bin/scheduler /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000
tar -cf $SUIT_NAME"fft.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-3 ./bin/scheduler /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000
tar -cf $SUIT_NAME"sort.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-3 ./bin/scheduler /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100
tar -cf $SUIT_NAME"sparselu.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-3 ./bin/scheduler /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096
tar -cf $SUIT_NAME"strassen.tar" *.csv; sudo rm *.csv; sleep 3;


SUIT_NAME="4b4l_A7_bots_"


taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36
tar -cf $SUIT_NAME"fib.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13
tar -cf $SUIT_NAME"nqueens.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input
tar -cf $SUIT_NAME"health.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20
tar -cf $SUIT_NAME"floorplan.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000
tar -cf $SUIT_NAME"fft.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000
tar -cf $SUIT_NAME"sort.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100
tar -cf $SUIT_NAME"sparselu.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096
tar -cf $SUIT_NAME"strassen.tar" *.csv; sudo rm *.csv; sleep 3;



# Changing flag from little to big
sed -i 's/#define PMCS_A7_ONLY/\/\/#define PMCS_A7_ONLY/' src/perf.hpp 
sed -i 's/\/\/#define PMCS_A15_ONLY/#define PMCS_A15_ONLY/' src/perf.hpp
make

SUIT_NAME="4b_bots_"

taskset -a -c 4-7 ./bin/scheduler /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36
tar -cf $SUIT_NAME"fib.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 4-7 ./bin/scheduler /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13
tar -cf $SUIT_NAME"nqueens.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 4-7 ./bin/scheduler /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input
tar -cf $SUIT_NAME"health.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 4-7 ./bin/scheduler /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20
tar -cf $SUIT_NAME"floorplan.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 4-7 ./bin/scheduler /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000
tar -cf $SUIT_NAME"fft.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 4-7 ./bin/scheduler /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000
tar -cf $SUIT_NAME"sort.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 4-7 ./bin/scheduler /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100
tar -cf $SUIT_NAME"sparselu.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 4-7 ./bin/scheduler /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096
tar -cf $SUIT_NAME"strassen.tar" *.csv; sudo rm *.csv; sleep 3;


SUIT_NAME="4b4l_A7_bots_"

taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36
tar -cf $SUIT_NAME"fib.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13
tar -cf $SUIT_NAME"nqueens.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input
tar -cf $SUIT_NAME"health.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20
tar -cf $SUIT_NAME"floorplan.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000
tar -cf $SUIT_NAME"fft.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000
tar -cf $SUIT_NAME"sort.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100
tar -cf $SUIT_NAME"sparselu.tar" *.csv; sudo rm *.csv; sleep 3;
taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096
tar -cf $SUIT_NAME"strassen.tar" *.csv; sudo rm *.csv; sleep 3;
