#!/bin/bash

#this order is the same as the scheduler execution
APPS=("fib" "nqueens" "health" "floorplan" "fft" "sort" "sparselu" "strassen" "backprop" "heartwall" "lavaMD" "particle_filter")
NUM_EXECUTIONS=10

rm -f *.dat

#In this function i assumed all outputs is in the same folder. Besides that, i assumed there are two columns: first column is the name and second column is the execution time.
#In this function i assumed each execution is in different folder. Besides that, each file has four column: 1º app_name, 2º timestamp_start, 3º timestamp_stop, 4º exec_time, 5º num_switch
#In this function i assumed all outputs is in the same folder. Besides that, i assumed there are two columns: first column is the name and second column is the execution time.
calculate_exec_time_default_case ()
{
for ((k = 0; k< ${#APPS[@]}; k++));
do 
   rm -f calculate_times
   cat */Exec_time_and_power.txt | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | awk '{print $2}' > start_times
   cat */Exec_time_and_power.txt | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | awk '{print $3}' > end_times
   paste start_times end_times -d ',' > app_times

   for ((i = 1; i<= 10; i++));
   do
        start=$(sed -n "${i}"p app_times | awk -F, '{print $1}')        
        end=$(sed -n "${i}"p app_times | awk -F, '{print $2}')
        StartDate=$(date -u -d "$start" +"%s")
        FinalDate=$(date -u -d "$end" +"%s")
        seconds=$(date -u -d "0 $FinalDate sec - $StartDate sec" +"%H:%M:%S" | awk -F: '{printf "%.2f", ($1*3600)+($2*60)+$3}')
        echo $seconds >> calculate_times
   done
      
   mean=$(cat calculate_times | tr "." "," | datamash mean 1 | tr "," "." | awk '{printf "%.2f", $1}')
   stdev=$(cat calculate_times | tr "." "," | datamash sstdev 1 | tr "," "."| awk '{printf "%.2f", $1}')
   root_squared=$(echo "sqrt ( 10 )" | bc -l)
   aux=$(echo $stdev/$root_squared)
   interval=$(echo $aux | awk '{printf "%.2f\n",$1*1.96}')

   echo -n $mean"," >> default_exec_time.dat
   #echo $stdev >> default_stdev
   echo -n $interval"," >> default_exec_time_error.dat
done
rm *times

}


calculate_power_default_case ()
{
#each folder has file with all aplications and its total power
for ((k = 0; k< ${#APPS[@]}; k++));
do   
   
   #DEFAULT CASE- 4b4l
   mean=$(cat */Exec_time_and_power.txt | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash mean 4 | tr "," "." | awk '{printf "%.2f", $1}')
   stdev=$(cat */Exec_time_and_power.txt | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash sstdev 4 | tr "," "."| awk '{printf "%.2f", $1}')
   root_squared=$(echo "sqrt ( 10 )" | bc -l)
   aux=$(echo $stdev/$root_squared)
   interval=$(echo $aux | awk '{printf "%.2f\n",$1*1.96}')

   echo -n $mean"," >> default_power.dat
   #echo $stdev >> default_stdev
   echo -n $interval"," >> default_power_error.dat
done

}
calculate_exec_time_dynamic_case()
{
for ((k = 0; k< ${#APPS[@]}; k++));
do 
   #EXECUTION TIME
   mean=$(cat */stderror* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash mean 4 | tr "," "."| awk '{printf "%.2f", $1}')
   stdev=$(cat */stderror* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash sstdev 4 | tr "," "."| awk '{printf "%.2f", $1}')
   root_squared=$(echo "sqrt ( 10 )" | bc -l)
   aux=$(echo $stdev/$root_squared)
   interval=$(echo $aux | awk '{printf "%.2f\n",$1*1.96}')
 
   echo -n $mean"," >> model_exec_time.dat
   echo -n $interval"," >> model_exec_time_error.dat


   #NUMBER OF SWITCH
   mean=$(cat */stderror* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash mean 5 | tr "," "."| awk '{printf "%.2f", $1}')
   stdev=$(cat */stderror* | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash sstdev 5 | tr "," "."| awk '{printf "%.2f", $1}')
   root_squared=$(echo "sqrt ( 10 )" | bc -l)
   aux=$(echo $stdev/$root_squared)
   interval=$(echo $aux | awk '{printf "%.2f\n",$1*1.96}')
 
   echo -n $mean"," >> model_number_switch.dat
   echo -n $interval"," >> model_number_switch_error.dat
 
done

}

#In this function i assumed each execution is in different folder. Besides that, each file has four column: 1º app_name, 2º timestamp_start, 3º timestamp_stop, 4º exec_time, 5º num_switch

calculate_power_dynamic_case()
{

folders=$(ls -d */)
for i in $folders;
do
     cd $i;     
     rm -f apps_total_energy *.total_energy
     for ((k = 0; k< ${#APPS[@]}; k++));
     do   
        #POWER
        start_time=$(cat stderror* | grep ${APPS[$k]} | awk -F "," '{print $2}')
        end_time=$(cat stderror* | grep ${APPS[$k]} | awk -F "," '{print $3}')
        sudo sed -n '/^\'$start_time'/,/^\'$end_time'/p' ${APPS[$k]}".energy" > interval_energy
        sed -i '1d' interval_energy #remove fisrt line, because the calculate begin after 1 second not in the zero time
        total=$(cat interval_energy | tr " " "\t" | tr "." "," | datamash sum 2 | tr "," ".")
        echo ${APPS[$k]}","$total >> "apps_total_energy"  #the order is the same from APPS

        #check is there are gaps in power
        #Get the start and end time and calculate how many seconds exist in the interval
        start=$(echo $start_time | sed 's/\[//g ; s/\]//g' | awk '{print $1}' )
        end=$(echo $end_time | sed 's/\[//g ; s/\]//g' | awk '{print $1}' )
               
        StartDate=$(date -u -d "$start" +"%s")
        FinalDate=$(date -u -d "$end" +"%s")
        seconds=$(date -u -d "0 $FinalDate sec - $StartDate sec" +"%H:%M:%S" | awk -F: '{print ($1*3600)+($2*60)+$3}')

        #If the total is the same number of line, the wattsup not failed
        num_lines=$(wc -l interval_energy | awk '{print $1}')

        if [ $seconds -ne $num_lines ]; then
            echo -n "Folder:"$i 
            echo -n " App:"${APPS[$k]}
            echo -n " Exec_time:"$seconds
            echo " Num_lines_power:"$num_lines
        fi 
        
     done
     rm interval_energy  
     
     cd ..;
done

for ((k = 0; k< ${#APPS[@]}; k++));
do
     cat */apps_total_energy | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash mean 2 | tr "," "." | awk '{printf "%.2f,", $1}' >> model_power.dat 
     cat */apps_total_energy | grep ${APPS[$k]} | tr "," "\t" | tr "." "," | datamash sstdev 2 | tr "," "." | awk '{printf "%.2f,", $1}' >> model_power_error.dat 
done 

rm -f apps_total_energy
}

calc_edp_dynamic_case()
{

for ((k = 0; k< ${#APPS[@]}; k++));
do
     cat */stderror* | grep ${APPS[$k]} | tr "," "\t" | tr "," "."| awk '{printf "%.2f\n", $4}' > exec_times

     rm -f powers
     folders=$(ls -d */)
     for i in $folders;
     do        
        cd $i;     
             start_time=$(cat stderror* | grep ${APPS[$k]} | awk -F "," '{print $2}')
             end_time=$(cat stderror* | grep ${APPS[$k]} | awk -F "," '{print $3}')
             sudo sed -n '/^\'$start_time'/,/^\'$end_time'/p' ${APPS[$k]}".energy" > interval_energy
             sed -i '1d' interval_energy #remove fisrt line, because the calculate begin after 1 second not in the zero time
             cat interval_energy | tr " " "\t" | tr "." "," | datamash sum 2 | tr "," "." >> ../powers
        cd ..
     done
     paste exec_times powers | awk '{printf "%.2f\n", $1*$2}' > edps
    
     mean=$(cat edps |  tr "." "," | datamash mean 1 | tr "," "." | awk '{printf "%.2f", $1}')
     stdev=$(cat edps |  tr "." "," | datamash sstdev 1 | tr "," "."| awk '{printf "%.2f", $1}')
     root_squared=$(echo "sqrt ( 10 )" | bc -l)
     aux=$(echo $stdev/$root_squared)
     interval=$(echo $aux | awk '{printf "%.2f\n",$1*1.96}')

     echo -n $mean"," >> model_edp.dat
     echo -n $interval"," >> model_edp_error.dat
          
done

rm -f powers edps exec_times

}

calculate_exec_time_dynamic_case
calculate_power_dynamic_case
calc_edp_dynamic_case
