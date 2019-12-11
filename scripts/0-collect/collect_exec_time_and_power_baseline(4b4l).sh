#!/bin/bash

#This script can be executed in any folder!!

rm -f Exec_time_and_power.txt error interval_energy *.energy 

APP_COMMANDS=("taskset -a -c 0-7 /home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 32" \
              "taskset -a -c 0-7 /home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 12" \
              "taskset -a -c 0-7 /home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input" \
              "taskset -a -c 0-7 /home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.15" \
              "taskset -a -c 0-7 /home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 1000000" \
              "taskset -a -c 0-7 /home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000" \
              "taskset -a -c 0-7 /home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 75 -m 75" \
              "taskset -a -c 0-7 /home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096" \
              "taskset -a -c 0-7 /home/odroid/workloads/rodinia/openmp/backprop/backprop 2000000" \
              "taskset -a -c 0-7 /home/odroid/workloads/rodinia/openmp/heartwall/heartwall /home/odroid/workloads/rodinia/data/heartwall/test.avi.part00 25" \
              "taskset -a -c 0-7 /home/odroid/workloads/rodinia/openmp/lavaMD/lavaMD -boxes1d 10" \
              "taskset -a -c 0-7 /home/odroid/workloads/rodinia/openmp/particlefilter/./particle_filter -x 256 -y 256 -z 20 -np 20000")

APP_NAMES=("fib" "nqueens" "health" "floorplan" "fft" "sort" "sparselu" "strassen" "backprop" "heartwall" "lavaMD" "particlefilter")



for ((i = 0; i<= 9; i++));
do
        for ((j = 0; j < ${#APP_COMMANDS[@]}; j++)); 
        do
              sudo wattsup -t -s ttyUSB0 watts > ${APP_NAMES[$j]}".energy" & pid_wattsup=$!
              echo "Pid wattsup:"$pid_wattsup
              sleep 5
              start=$(date +"%H:%M:%S")
              ${APP_COMMANDS[$j]} & pid_app=$! 
              wait $pid_app
              end=$(date +"%H:%M:%S")
              sleep 5
              var=$(($pid_wattsup +2))
              sudo kill -9 $var
              sleep 5

              echo $start
              echo $end
              sudo sed -i 's/\[//g ; s/\]//g' ${APP_NAMES[$j]}".energy"
              sudo sed -n "/^${start}/,/^${end}/p" ${APP_NAMES[$j]}".energy" > interval_energy
              sed -i '1d' interval_energy #remove fisrt line, because the calculate begin after 1 second not in the zero time

              StartDate=$(date -u -d "$start" +"%s")
              FinalDate=$(date -u -d "$end" +"%s")
              seconds=$(date -u -d "0 $FinalDate sec - $StartDate sec" +"%H:%M:%S" | awk -F: '{print ($1*3600)+($2*60)+$3}')


              num_lines=$(wc -l interval_energy | awk '{print $1}')

              if [ $seconds -ne $num_lines ]; then
                  echo -n " App:"${APP_NAMES[$j]} >> error
                  echo -n " Exec_time:"$seconds >> error
                  echo " Num_lines_power:"$num_lines >> error
              fi 

              total=$(cat interval_energy | tr " " "\t" | datamash sum 2)
              echo ${APP_NAMES[$j]}","$start","$end","$total >> "Exec_time_and_power.txt" 
        done
        tar -cf $i".tar" *.energy Exec_time_and_power.txt error
        rm -f Exec_time_and_power.txt error interval_energy *.energy
done

