#!/bin/sh

: '

This is the file plot_energy.py

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import sys

NUM=int(sys.argv[1])

if len(sys.argv) < 2:
  print("Miss argument")
  
data = pd.read_csv("energy_all.postprocess",header=None) #pandas will assume the first row is the header.
fig, axs = plt.subplots(NUM)
fig.suptitle('Sharing both axes')

for i in range(NUM):
   axs[i].plot(data.iloc[:,i])

plt.savefig('plot.png')
'

restart_script ()
{
    rm -f *.csv 
 
    FOLDERS=`ls -d */`
    for i in $FOLDERS ;
    do
       rm -f -r $i
    done

    cp /home/diego/Downloads/backup_energy/*.tar .

    FOLDERS=`ls *.tar`
    for i in $FOLDERS ;
    do
       tar -xf $i
    done
    rm *.tar

    #read -p "Clear and copy all folders. Press enter to continue!"
}

#This function is responsible to check if happens some problems during power collect
#If exist, we need to collect again!
check_energy_measurements(){   

   FOLDERS=`ls -d */`
   for i in $FOLDERS ;
   do
       cd $i;     
       
       rm -f *.dat

       MIN_LINES=$(wc -l *.energy | awk '{print $1}' | sed '$d' | datamash min 1) 
       MAX_LINES=$(wc -l *.energy | awk '{print $1}' | sed '$d' | datamash max 1) 
       DIFF=$(echo "$MAX_LINES $MIN_LINES" | awk '{print $1-$2}')

       flag=0
       if [ $DIFF -gt 10 ] 
       then
           flag=1
           echo "You need to collect energy again to folder " $i ". But you just need to get again outliers files, not all"
       fi
       
       if [ $flag -eq 1 ]
       then
           exit 1
       fi          
       cd ..;
   done
}


#This function is responsible to group pmcs by second to be compatible with the power collection. After that, all files have the same number of line.
#The next step is to calculate the average for cycles and power
map_pmcs_to_energy()
{
   folders=`ls -d */` 
   for f in $folders ;
   do
       cd $f
       files=`ls *.energy` 
       for file in $files ;
       do           
           name=$(echo "$file" | cut -f 1 -d '.') 
           #just remove the format of timestamp to join with pmcs
           cat $file | sed -re 's/[[]/ /g' | sed -re 's/] /,/g' > temp
           mv temp $name".aux_energy"
        done
        cd ..
   done

   folders=`ls -d */` 
   for f in $folders ;
   do
       cd $f
       rm -f consolidate* times.txt

       files=`ls *.csv` 
       for file in $files ;
       do
          #remove the extension of a filename 
          name=$(echo "$file" | cut -f 1 -d '.') 
          #agrupando os pmcs dentro de 1 segundo
          if echo "$f" | grep "4b4l_A[5-9]" 1> out || echo "$f" | grep '^4l\_[a-z]*' 1> out
          then      
              cat $file | sed -re 's/[[]/ /g' | sed -re 's/] /,/g' | tr "," "\t"  | tr "." "," | datamash -s -g 1 mean 2-6 | tr "," "." | tr "\t" "," > temp
          elif echo "$f" | grep "4b4l_A1[0-9]" 1> out || echo "$f" | grep '4b_[a-z]*' 1> out
          then
               cat $file | sed -re 's/[[]/ /g' | sed -re 's/] /,/g' | tr "," "\t"  | tr "." "," | datamash -s -g 1 mean 2-8 | tr "," "." | tr "\t" "," > temp
          else
               echo "Invalid argument!!"
               exit -1
          fi

          mv temp $name".aux_pmcs"

          #join entre os pmcs já calculados a média e o cálculo da energia
          join -t , $name".aux_pmcs" $name".aux_energy"  > temp
          mv temp $name".map"
        
          #check if someone stay out after join
          n2=$(wc -l $name".aux_pmcs" | awk '{print $1}')
          n1=$(wc -l $name".map" | awk '{print $1}')
                 
          if [ $n1 -gt $n2 ]
          then
             echo "In "$f "File " $file
             echo "Some lines was dropped during the join. Lines for pmcs "$n1". Lines for energy "$n2 
          fi               

          #calculate execution time
          original_start_time=$(cat $file | awk -F',' 'NR==2{print $1}')
          original_end_time=$(cat $file | awk -F',' 'END{print $1}')
          start=$(echo $original_start_time | sed 's/\[//g ; s/\]//g' | awk '{print $1}' )
          end=$(echo $original_end_time | sed 's/\[//g ; s/\]//g' | awk '{print $1}' )
          StartDate=$(date -u -d "$start" +"%s")
          FinalDate=$(date -u -d "$end" +"%s")
          seconds=$(date -u -d "0 $FinalDate sec - $StartDate sec" +"%H:%M:%S" | awk -F: '{print ($1*3600)+($2*60)+$3}')
          echo $seconds >> times.txt

          #remove the timestamp column. Is not necessary 
          cut -d, -f1 --complement $name".map" > aux
          mv aux $name".map"
                   
       done  

       MIN_PMCS=$(wc -l *.map | awk '{print $1}' | sed '$d' | datamash min 1)
       sed -i -n "1,$MIN_PMCS p" *.map
       
       cat times.txt | tr "." "," | datamash mean 1 | tr "," "." > exec_time.average
       
       rm -f aux* *.aux_pmcs *.aux_energy
                
       cd ..
   done

}

agregate_pmcs ()
{
   folders=`ls -d */` 
   for f in $folders ;
   do
       cd $f

       count=-1
       files=`ls *.map` #cada csv possui 4 pmcs
       for file in $files ;
       do
           count=$(($count + 1)) 
           if echo "$f" | grep "4b4l_A[5-9]" 1> out || echo "$f" | grep '^4l\_[a-z]*' 1> out
           then 
                cat $file | awk -F "," '{printf "%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n",$1,$2,$3,$4,$5,$6}' >  $count".dat"  
           elif echo "$f" | grep "4b4l_A1[0-9]" 1> out || echo "$f" | grep '4b_[a-z]*' 1> out
           then
                cat $file | awk -F "," '{printf "%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n", $1,$2,$3,$4,$5,$6,$7,$8}' > $count".dat"
           fi
       done
                 
       if echo "$f" | grep "4b4l_A[5-9]" 1> out || echo "$f" | grep '^4l\_[a-z]*' 1> out
       then  
            #the last file just have one pmcs, the other three are null. Especific for A7
            cat $count".dat" | cut -d, -f1,2 > temp; mv temp $count".dat"  
       elif echo "$f" | grep "4b4l_A1[0-9]" 1> out || echo "$f" | grep '4b_[a-z]*' 1> out
       then 
            #the last file just have two pmcs, the other four are null. But it was necessary add ONE MORE BEACUSE NOW CYCLES
            cat $count".dat" | cut -d, -f1,2,3 > temp; mv temp $count".dat" 
       fi

       paste *.dat -d "," > aux1
       rm *.dat 

       if echo "$f" | grep "4b4l_A[5-9]" 1> out || echo "$f" | grep '^4l\_[a-z]*' 1> out
       then  
               #calculate the power average and cycles average
               cat aux1 | awk -F, '{printf "%.4f\n", ($1+$7+$13+$19+$25+$31+$37+$43+$49)/9}' > cycles_avg
               cat aux1 | awk -F, '{printf "%.4f\n", ($6+$12+$18+$24+$30+$36+$42+$48+$54)/9}' > power_avg

               #remove all power and cycles
               cut -d, -f1,6,7,12,13,18,19,24,25,30,31,36,37,42,43,48,49,54 --complement aux1 > aux2
               paste cycles_avg aux2 power_avg -d "," > consolidated-pmc-little.csv

       elif echo "$f" | grep "4b4l_A1[0-9]" 1> out || echo "$f" | grep '4b_[a-z]*' 1> out
       then 
               #calculate the power average and cycles average
               cat aux1 | awk -F, '{printf "%.4f\n", ($1+$9+$17+$25+$33+$41+$49+$57+$65+$73)/10}' > cycles_avg
               cat aux1 | awk -F, '{printf "%.4f\n", ($8+$16+$24+$32+$40+$48+$56+$64+$72+$80)/10}' > power_avg

               #remove all power and cycles
               cut -d, -f1,8,9,16,17,24,25,32,33,40,41,48,49,56,57,64,65,72,73,80 --complement aux1 > aux2

               paste cycles_avg aux2 power_avg -d "," > consolidated-pmc-big.csv
       fi

       rm -f aux* *_avg out
       cd ..
   done
          
}


create_dataset_single_target ()
{
   #APPS=("fib" "nqueens" "health" "floorplan" "fft" "sort" "sparselu" "strassen")
   APPS=("nqueens")

   #A7 and A15 need to have the same number of lines
   for ((j = 0; j < ${#APPS[@]}; j++));
   do 
       MIN_LINES=$(wc -l 4b4l_*${APPS[$j]}/consolidate* | awk '{print $1}' | datamash min 1)

       sed -n "1,$MIN_LINES p" 4b4l_A7_bots_${APPS[$j]}/consolidated-pmc-little.csv > 4b4l_A7_bots_${APPS[$j]}/aux;
       mv 4b4l_A7_bots_${APPS[$j]}/aux 4b4l_A7_bots_${APPS[$j]}/consolidated-pmc-big.csv         
       sed -n "1,$MIN_LINES p" 4b4l_A15_bots_${APPS[$j]}/consolidated-pmc-big.csv > 4b4l_A15_bots_${APPS[$j]}/aux;
       mv 4b4l_A15_bots_${APPS[$j]}/aux 4b4l_A15_bots_${APPS[$j]}/consolidated-pmc-big.csv 

   done

   rm -f *single_target.csv

   cat 4l_*/consolidated-pmc-little.csv | awk -F "," '{print}' >> 4l_single_target.csv
   cat 4b_*/consolidated-pmc-big.csv | awk -F "," '{print}' >> 4b_single_target.csv
   cat 4b4l_A7_*/consolidated-pmc-little.csv | awk -F "," '{print}' >> 4b4l_A7_single_target.csv
   cat 4b4l_A15_*/consolidated-pmc-big.csv | awk -F "," '{print}' >> 4b4l_A15_single_target.csv

   #Get the last column
   cat 4b4l_A7_single_target.csv | awk -F, '{print $(NF)}' > Energy_A7
   cat 4b4l_A15_single_target.csv | awk -F, '{print $(NF)}' > Energy_A15  
   paste Energy_A7 Energy_A15 -d "," > All_energy
   cat All_energy | tr "," "\t" | awk '{printf "%.2f\n", ($1+$2)/2}' > Average_power

   #remove power and cycles
   cut -d, -f35 --complement 4b4l_A7_single_target.csv > aux1
   cut -d, -f58 --complement 4b4l_A15_single_target.csv > aux2

   paste aux1 aux2 Average_power -d "," > 4b4l_single_target.csv


   sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,power' 4l_single_target.csv
   sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,power' 4b4l_A7_single_target.csv
   sed  -i '1i CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x71,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power' 4b_single_target.csv
   sed  -i '1i CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x71,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power' 4b4l_A15_single_target.csv
   sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x71,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power' 4b4l_single_target.csv

   rm aux* Energy_* Average* All_energy
}

create_dataset_multi_target ()
{
   #printf "This script use other script responsible to create consolidate.csv file for each config and each application. \n"
   #read -p "Press enter in case already executed it before.."

   #Essa ordem é importante pois o plot assume ordem igual
   #APPS=("fib" "nqueens" "health" "floorplan" "fft" "sort" "sparselu" "strassen")
   APPS=("nqueens")

   #A primeira coisa a ser feita é descobrir para cada aplicação, qual configuração teve o menor tempo. 
   #Após isso, todas as outras confgurações deverá ter relação igual ou superior a 1. Essa relação será armazenada na variável "tics"

   for ((j = 0; j < ${#APPS[@]}; j++));
   do             
          MIN_LINES=$(wc -l *${APPS[$j]}/consolidated* | awk '{print $1}' | datamash min 1)
          folders=$(ls -d *${APPS[$j]})
          for i in $folders ;
          do             
             rm -f consolidate.tics               
             cd $i;          
                     current=$(wc -l consolidated* | awk '{print $1}')
                     result=$(echo "scale=1; $current / $MIN_LINES" | bc)
                     tics=`/usr/bin/printf "%.0f" $result` #Round to up or down
                     num_columns=$(cat consolidate* | awk -F, '{print NF; exit}')
                     for num in $(seq 1 $num_columns);     
                     do                                    
                           cat consolidate* | awk -F, -v col=$num  "{sum += (\$col); if (NR % $tics == 0) {print (sum/$tics); sum=0}}" > $num".temp"                              
                     done
             cd ..          
          done
   done

   #Devido a uma aproximação na variável tics, os arquivos finais poderão ter um número de linhas MAIOR ou MENOR do que foi calculado anteriormente.
   #Por isso, mais uma vez devemos igualar o número de linhas a configuração que está com o menor número de linhas.

   for ((j = 0; j < ${#APPS[@]}; j++));
   do   
          MIN_LINES=$(wc -l *${APPS[$j]}/1".temp" | awk '{print $1}' | datamash min 1)
          folders=$(ls -d *${APPS[$j]})
          for i in $folders ;
          do          
             cd $i;  
             paste -d, $(ls -v *.temp) > pmcs.tics
             sed -n "1,$MIN_LINES p" pmcs.tics > aux
             mv aux pmcs.tics
             rm *.temp
             cd ..    
          done
   done
           
   #Essa última etapa é feito o cálculo dos targets para cada configuração e adicionado ao final do arquivo.

   #Primeiro é inserido todas as coletas de cada configuração. Todos os arquivos terão o mesmo número de linhas.
   cat 4l_*/pmcs.tics > 4l.aux
   cat 4b_*/pmcs.tics > 4b.aux
   cat 4b4l_A7*/pmcs.tics > 4b4l_A7.aux
   cat 4b4l_A15*/pmcs.tics > 4b4l_A15.aux

   #obtendo a última coluna(power) de cada arquivo
   cat 4l.aux | awk -F "," '{print $NF}' > 4l_target.aux
   cat 4b.aux | awk -F "," '{print $NF}' > 4b_target.aux
   cat 4b4l_A7.aux | awk -F "," '{print $NF}' > 4b4l_A7_target.aux
   cat 4b4l_A15.aux | awk -F "," '{print $NF}' > 4b4l_A15_target.aux
   paste -d "," 4b4l_A7_target.aux 4b4l_A15_target.aux | awk -F "," '{print ($1+$2)*0.50}' > 4b4l_target.aux

   #Gerando o target a ser incluido em todoso os files
   paste -d "," 4l_target.aux 4b_target.aux 4b4l_target.aux > columns_target 

   #Obtendo os pmcs sem o power
   cat 4l.aux | awk -F, 'NF-=1' | tr " " "," > 4l.temp
   cat 4b.aux | awk -F, 'NF-=1' | tr " " "," > 4b.temp
   cat 4b4l_A7.aux | awk -F, 'NF-=1' | tr " " "," > 4b4l_A7.temp
   cat 4b4l_A15.aux | awk -F, 'NF-=1' | tr " " "," > 4b4l_A15.temp

   #Adicionando os targets para cada arquivo
   paste -d "," 4l.temp columns_target > 4l_multi_target.csv
   paste -d "," 4b.temp columns_target > 4b_multi_target.csv
   paste -d "," 4b4l_A7.temp columns_target > 4b4l_A7_multi_target.csv
   paste -d "," 4b4l_A15.temp columns_target > 4b4l_A15_multi_target.csv

   cat 4b4l_A7_multi_target.csv | awk -F, 'NF-=3' | tr " " "," > 4b4l.temp
   paste -d "," 4b4l.temp 4b4l_A15_multi_target.csv > 4b4l_multi_target.csv

   sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,power4l,power4b,power4b4l' 4l_multi_target.csv
   sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,power4l,power4b,power4b4l' 4b4l_A7_multi_target.csv
   sed  -i '1i CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power4l,power4b,power4b4l' 4b_multi_target.csv
   sed  -i '1i CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power4l,power4b,power4b4l' 4b4l_A15_multi_target.csv
   sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power4l,power4b,power4b4l' 4b4l_multi_target.csv

   rm -f *.aux *temp columns_target
}

create_dataset_performance_multitarget ()
{
   #Get the execution time from each config
   cat 4b4l_A7*/exec_time.average > 4b4l_1
   cat 4b4l_A15*/exec_time.average > 4b4l_2
   cat 4b_*/exec_time.average > 4b
   cat 4l_*/exec_time.average > 4l

   paste 4b4l_1 4b4l_2 | awk '{print ($1+$2)*0.50}' > 4b4l

   paste 4b4l 4b 4l | awk '{printf "%.6f,%.6f\n", $3/$2, $3/$1}' > speedup_4l
   paste 4b4l 4b 4l | awk '{printf "%.6f,%.6f\n", $2/$3, $2/$1}' > speedup_4b
   paste 4b4l 4b 4l | awk '{printf "%.6f,%.6f\n", $1/$3, $1/$2}' > speedup_4b4l 

   rm 4b4l 4b4l_1 4b4l_2 4b 4l 

   #Calculate the average for each feature 
   folders=`ls -d */` 
   for f in $folders ;
   do
       cd $f
       if echo "$f" | grep "4b4l_A[5-9]" 1> out || echo "$f" | grep '^4l\_[a-z]*' 1> out
       then 
             cat consolidated* | tr "," "\t" | tr "." "," | datamash mean 1-34 | tr "," "." | tr "\t" "," > aux
             mv aux consolidated-pmc-little.average;
       elif echo "$f" | grep "4b4l_A1[0-9]" 1> out || echo "$f" | grep '4b_[a-z]*' 1> out
       then
             cat consolidated* | tr "," "\t" | tr "." "," | datamash mean 1-57 | tr "," "." | tr "\t" "," > aux
             mv aux consolidated-pmc-big.average; 
       fi
       cd ..
   done

   #------------------------------
   #Calculate dataset for 4little
   #------------------------------
   cat 4l_*/consolidated-pmc-little.average | awk -F "," '{print}' > 4l_performance_multitarget.csv
   cat speedup_4l | tr "," " " | awk  '{print $2}' > to_4b4l
   cat speedup_4l | tr "," " " | awk  '{print $1}' > to_4b
   awk '$0=$0",1"' 4l_performance_multitarget.csv > temp #add 1 última coluna
   paste temp to_4b to_4b4l -d "," > 4l_performance_multitarget.csv
   rm to_* 

   #--------------------------
   #Calculate dataset for 4big
   #--------------------------
   
   cat 4b_*/consolidated-pmc-big.average | awk -F "," '{print}' > 4b_performance_multitarget.csv
   cat speedup_4b | tr "," " " | awk  '{print $2}' > to_4b4l
   cat speedup_4b | tr "," " " | awk  '{print $1}' > to_4l
   paste 4b_performance_multitarget.csv to_4l -d "," > temp1
   awk '$0=$0",1"' temp1 > temp2
   paste temp2 to_4b4l -d "," > 4b_performance_multitarget.csv
   rm to_*  
   
   
   #--------------------------
   #Calculate dataset for 4b4l
   #--------------------------
   cat 4b4l_A15_*/consolidated-pmc-big.average | awk -F "," '{print}' > average_samples_A15
   cat 4b4l_A7_*/consolidated-pmc-little.average | awk -F "," '{print}' > average_samples_A7
   
   cat speedup_4b4l | tr "," " " | awk '{print $2}' > to_4b
   cat speedup_4b4l | tr "," " " | awk '{print $1}' > to_4l
   
   paste average_samples_A7 average_samples_A15 -d "," > 4b4l_performance_multitarget.csv
   paste 4b4l_performance_multitarget.csv to_4l to_4b -d "," > temp
   awk '$0=$0",1"' temp > 4b4l_performance_multitarget.csv
   
   rm to_* average_samples_* temp*
   
   sed -i 's/,,/,/g' 4l_performance_multitarget.csv
   sed -i 's/,,/,/g' 4b_performance_multitarget.csv
   sed -i 's/,,/,/g' 4b4l_performance_multitarget.csv
   
   rm speedup*
   
   sed -i '1s/^/CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,speedup4l,speedup4b,speedup4b4l \n/' 4b_performance_multitarget.csv
   sed -i '1s/^/cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,speedup4l,speedup4b,speedup4b4l \n/' 4l_performance_multitarget.csv
   sed -i '1s/^/cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,speedup4l,speedup4b,speedup4b4l \n/' 4b4l_performance_multitarget.csv

}


echo "1 - check_energy"
check_energy_measurements
echo "2 - map pmcs to energy"
map_pmcs_to_energy
echo "3 - agregate pmcs"
agregate_pmcs
echo "4 - create dataset power single target"
create_dataset_power_singletarget
echo "5 - create dataset power multi target"
create_dataset_power_multitarget 
echo "6 - create dataset performance multi target"
create_dataset_performance_multitarget
