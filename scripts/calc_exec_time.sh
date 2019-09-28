#!/bin/bash


APPS=("fib" "health" "floorplan" "fft" "sort" "sparselu" "strassen" "backprop" "heartwall" "lavaMD" "particle_filter")
NUM_EXECUTIONS=10

rm -f *.dat

for ((k = 0; k< ${#APPS[@]}; k++));
do   
   #DEFAULT CASE- 4b4l
   mean=$(cat default_exp* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash mean 2 | tr "," "." | awk '{printf "%.2f", $1}')
   stdev=$(cat default_exp* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash sstdev 2 | tr "," "."| awk '{printf "%.2f", $1}')
   root_squared=$(echo "sqrt ( 10 )" | bc -l)
   aux=$(echo $stdev/$root_squared)
   interval=$(echo $aux | awk '{printf "%.2f\n",$1*1.96}')

   echo -n $mean"," >> default_exec_time.dat
   #echo $stdev >> default_stdev
   echo -n $interval"," >> default_exec_time_error.dat


   #MODEL - EXECUTION TIME
   mean=$(cat stderror* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash mean 2 | tr "," "."| awk '{printf "%.2f", $1}')
   stdev=$(cat stderror* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash sstdev 2 | tr "," "."| awk '{printf "%.2f", $1}')
   aux=$(echo $stdev/$root_squared)
   interval=$(echo $aux | awk '{printf "%.2f\n",$1*1.96}')
 
   echo -n $mean"," >> model_exec_time.dat
   echo -n $interval"," >> model_exec_time_error.dat



   #MODEL - NUMBER OF SWITCH
   mean=$(cat stderror* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash mean 3 | tr "," "."| awk '{printf "%.2f", $1}')
   stdev=$(cat stderror* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash sstdev 3 | tr "," "."| awk '{printf "%.2f", $1}')
   aux=$(echo $stdev/$root_squared)
   interval=$(echo $aux | awk '{printf "%.2f\n",$1*1.96}')
 
   echo -n $mean"," >> model_number_switch.dat
   echo -n $interval"," >> model_number_switch_error.dat

done
