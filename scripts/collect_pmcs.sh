#!/bin/bash

#You need to be sudo to execute this script

#Setup freq to maximum

for i in 0 1 2 3 4 5 6 7  
do
  echo performance > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor;
done

make

rm -f -- *.csv

SUIT_NAME="4l_bots_"

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36
mkdir $SUIT_NAME"fib"; mv *.csv $SUIT_NAME"fib"; tar -cf $SUIT_NAME"fib.tar" $SUIT_NAME"fib";
rm -r $SUIT_NAME"fib"; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13
mkdir $SUIT_NAME"nqueens"; mv *.csv $SUIT_NAME"nqueens"; tar -cf $SUIT_NAME"nqueens.tar" $SUIT_NAME"nqueens";
rm -r $SUIT_NAME"nqueens"; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input
mkdir $SUIT_NAME"health"; mv *.csv $SUIT_NAME"health"; tar -cf $SUIT_NAME"health.tar" $SUIT_NAME"health"
rm -r $SUIT_NAME"health"; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20
mkdir $SUIT_NAME"floorplan"; mv *.csv $SUIT_NAME"floorplan"; tar -cf $SUIT_NAME"floorplan.tar" $SUIT_NAME"floorplan"
rm -r $SUIT_NAME"floorplan"; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000
mkdir $SUIT_NAME"fft" ; mv *.csv $SUIT_NAME"fft"; tar -cf $SUIT_NAME"fft.tar" $SUIT_NAME"fft"
rm -r $SUIT_NAME"fft" ; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000
mkdir $SUIT_NAME"sort"; mv *.csv $SUIT_NAME"sort" ; tar -cf $SUIT_NAME"sort.tar" $SUIT_NAME"sort"
rm -r $SUIT_NAME"sort" ; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100
mkdir $SUIT_NAME"sparselu" ; mv *.csv $SUIT_NAME"sparselu" ; tar -cf $SUIT_NAME"sparselu.tar" $SUIT_NAME"sparselu"
rm -r $SUIT_NAME"sparselu" ; sleep 3;

taskset -a -c 0-3 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096
mkdir $SUIT_NAME"strassen" ; mv *csv $SUIT_NAME"strassen" ; tar -cf $SUIT_NAME"strassen.tar" $SUIT_NAME"strassen"
rm -r $SUIT_NAME"strassen" ; sleep 3;


SUIT_NAME="4b4l_A7_bots_"


taskset -a -c 0-7 ./bin/scheduler__A7 /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36
mkdir $SUIT_NAME"fib"; mv *.csv $SUIT_NAME"fib"; tar -cf $SUIT_NAME"fib.tar" $SUIT_NAME"fib";
rm -r $SUIT_NAME"fib"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13
mkdir $SUIT_NAME"nqueens"; mv *.csv $SUIT_NAME"nqueens"; tar -cf $SUIT_NAME"nqueens.tar" $SUIT_NAME"nqueens";
rm -r $SUIT_NAME"nqueens"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input
mkdir $SUIT_NAME"health"; mv *.csv $SUIT_NAME"health"; tar -cf $SUIT_NAME"health.tar" $SUIT_NAME"health"
rm -r $SUIT_NAME"health"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20
mkdir $SUIT_NAME"floorplan"; mv *.csv $SUIT_NAME"floorplan"; tar -cf $SUIT_NAME"floorplan.tar" $SUIT_NAME"floorplan"
rm -r $SUIT_NAME"floorplan"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000
mkdir $SUIT_NAME"fft" ; mv *.csv $SUIT_NAME"fft"; tar -cf $SUIT_NAME"fft.tar" $SUIT_NAME"fft"
rm -r $SUIT_NAME"fft" ; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000
mkdir $SUIT_NAME"sort"; mv *.csv $SUIT_NAME"sort" ; tar -cf $SUIT_NAME"sort.tar" $SUIT_NAME"sort"
rm -r $SUIT_NAME"sort" ; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100
mkdir $SUIT_NAME"sparselu" ; mv *.csv $SUIT_NAME"sparselu" ; tar -cf $SUIT_NAME"sparselu.tar" $SUIT_NAME"sparselu"
rm -r $SUIT_NAME"sparselu" ; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A7 /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096
mkdir $SUIT_NAME"strassen" ; mv *csv $SUIT_NAME"strassen" ; tar -cf $SUIT_NAME"strassen.tar" $SUIT_NAME"strassen"
rm -r $SUIT_NAME"strassen" ; sleep 3;



SUIT_NAME="4b_bots_"

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36
mkdir $SUIT_NAME"fib"; mv *.csv $SUIT_NAME"fib"; tar -cf $SUIT_NAME"fib.tar" $SUIT_NAME"fib";
rm -r $SUIT_NAME"fib"; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13
mkdir $SUIT_NAME"nqueens"; mv *.csv $SUIT_NAME"nqueens"; tar -cf $SUIT_NAME"nqueens.tar" $SUIT_NAME"nqueens";
rm -r $SUIT_NAME"nqueens"; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input
mkdir $SUIT_NAME"health"; mv *.csv $SUIT_NAME"health"; tar -cf $SUIT_NAME"health.tar" $SUIT_NAME"health"
rm -r $SUIT_NAME"health"; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20
mkdir $SUIT_NAME"floorplan"; mv *.csv $SUIT_NAME"floorplan"; tar -cf $SUIT_NAME"floorplan.tar" $SUIT_NAME"floorplan"
rm -r $SUIT_NAME"floorplan"; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000
mkdir $SUIT_NAME"fft" ; mv *.csv $SUIT_NAME"fft"; tar -cf $SUIT_NAME"fft.tar" $SUIT_NAME"fft"
rm -r $SUIT_NAME"fft" ; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000
mkdir $SUIT_NAME"sort"; mv *.csv $SUIT_NAME"sort" ; tar -cf $SUIT_NAME"sort.tar" $SUIT_NAME"sort"
rm -r $SUIT_NAME"sort" ; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100
mkdir $SUIT_NAME"sparselu" ; mv *.csv $SUIT_NAME"sparselu" ; tar -cf $SUIT_NAME"sparselu.tar" $SUIT_NAME"sparselu"
rm -r $SUIT_NAME"sparselu" ; sleep 3;

taskset -a -c 4-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096
mkdir $SUIT_NAME"strassen" ; mv *csv $SUIT_NAME"strassen" ; tar -cf $SUIT_NAME"strassen.tar" $SUIT_NAME"strassen"
rm -r $SUIT_NAME"strassen" ; sleep 3;



SUIT_NAME="4b4l_A15_bots_"

taskset -a -c 0-7 ./bin/scheduler /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36
mkdir $SUIT_NAME"fib"; mv *.csv $SUIT_NAME"fib"; tar -cf $SUIT_NAME"fib.tar" $SUIT_NAME"fib";
rm -r $SUIT_NAME"fib"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13
mkdir $SUIT_NAME"nqueens"; mv *.csv $SUIT_NAME"nqueens"; tar -cf $SUIT_NAME"nqueens.tar" $SUIT_NAME"nqueens";
rm -r $SUIT_NAME"nqueens"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input
mkdir $SUIT_NAME"health"; mv *.csv $SUIT_NAME"health"; tar -cf $SUIT_NAME"health.tar" $SUIT_NAME"health"
rm -r $SUIT_NAME"health"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20
mkdir $SUIT_NAME"floorplan"; mv *.csv $SUIT_NAME"floorplan"; tar -cf $SUIT_NAME"floorplan.tar" $SUIT_NAME"floorplan"
rm -r $SUIT_NAME"floorplan"; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000
mkdir $SUIT_NAME"fft" ; mv *.csv $SUIT_NAME"fft"; tar -cf $SUIT_NAME"fft.tar" $SUIT_NAME"fft"
rm -r $SUIT_NAME"fft" ; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000
mkdir $SUIT_NAME"sort"; mv *.csv $SUIT_NAME"sort" ; tar -cf $SUIT_NAME"sort.tar" $SUIT_NAME"sort"
rm -r $SUIT_NAME"sort" ; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100
mkdir $SUIT_NAME"sparselu" ; mv *.csv $SUIT_NAME"sparselu" ; tar -cf $SUIT_NAME"sparselu.tar" $SUIT_NAME"sparselu"
rm -r $SUIT_NAME"sparselu" ; sleep 3;

taskset -a -c 0-7 ./bin/scheduler_A15 /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096
mkdir $SUIT_NAME"strassen" ; mv *csv $SUIT_NAME"strassen" ; tar -cf $SUIT_NAME"strassen.tar" $SUIT_NAME"strassen"
rm -r $SUIT_NAME"strassen" ; sleep 3;


