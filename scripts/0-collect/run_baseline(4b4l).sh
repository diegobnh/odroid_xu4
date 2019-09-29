#!/bin/bash


start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "fib,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "nqueens,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "health,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "floorplan,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "fft,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "sort,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "sparselu,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "strassen,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/rodinia/openmp/backprop/backprop 10000000; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "backprop,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/rodinia/openmp/heartwall/heartwall /home/odroid/workloads/rodinia/data/heartwall/test.avi.part00 50; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "heartwall,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/rodinia/openmp/lavaMD/lavaMD -boxes1d 20; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "lavaMD,"$runtime
start=$(date +%s.%N); taskset -a -c 0-7 /home/odroid/workloads/rodinia/openmp/particlefilter/./particle_filter -x 512 -y 512 -z 40 -np 40000; end=$(date +%s.%N); runtime=$(python -c "print(${end} - ${start})"); 1>&2 echo "particle_filter,"$runtime



