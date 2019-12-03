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

plot_watts_per_app () {
   gather_energy_measurements

   FOLDERS=`ls -d 4l_* 4b4l_A7*`
   for i in $FOLDERS ;
   do
       cd $i;          
       #python3 ../plot_energy.py 9      
       cd ..;
   done
   
   FOLDERS=`ls -d 4b_* 4b4l_A15*`
   for i in $FOLDERS ;
   do
       cd $i;          
       #python3 ../plot_energy.py 9      
       cd ..;
   done
}

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


check_energy_measurements(){   
   FOLDERS=`ls -d */`
   for i in $FOLDERS ;
   do
       cd $i;     
       
       rm -f *.dat
       #for f in *.energy; do 
       #     name=$(echo "$f" | cut -f 1 -d '.')               
       #     cat $f | awk '{print $2}' > $name".dat"                  
       #done
   

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

       #sed -i -n "1,$MIN_LINES p" *.dat

       #paste *.dat -d ',' > energy_all.postprocess
       
       #python3 ../plot_energy.py 10  #10 total performance counter
       #rm *.dat
       cd ..;
   done
}


#This function is responsible to group pmcs by second to be compatible with the power collection. After that, all files have the same number of line.
#The next step is to calculate the average for cycles and power
map_pmcs_to_energy()
{
        #If you get here, is because all the energy files are nearly equals.
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

                files=`ls *.csv` #cada csv possui 4 pmcs
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
                   
                   if [ $n1 -ne $n2 ]
                   then
                      echo "Some lines was dropped during the join. Lines for pmcs "$n1". Lines for energy "$n2 " Folder "$f 
                   fi
		   
		   #remove the timestamp column. Is not necessary 
                   cut -d, -f1 --complement $name".map" > aux
                   mv aux $name".map" 
                done  

                MIN_PMCS=$(wc -l *.map | awk '{print $1}' | sed '$d' | datamash min 1)
                sed -i -n "1,$MIN_PMCS p" *.map

                rm -f aux* *.aux_pmcs *.aux_energy
		
                cd ..
        done

}


create_dataset ()
{
     if [ $1 = "little" ]; then
         OUTPUT_FILE_NAME="consolidated-pmc-little.csv"
         count=-1
         files=`ls *.csv` #cada csv possui 4 pmcs
         for file in $files ;
         do
             count=$(($count + 1))              
             cat $file | awk -F "," '{printf "%.4f,%.4f,%.4f,%.4f,%.4f\n", $2,$3,$4,$5,$6}' >  $count".dat"                   
             #If you want to normalize by cycles, use this line below
             #cat $file | awk -F "," '{printf "%.4f,%.4f,%.4f,%.4f\n", $3/$2,$4/$2,$5/$2,$6/$2}' >  $count".dat"  
         done
         #If you want to normalize, just cut -f1
         #the last file just have one pmcs, the other three are null. It was necessary add ONE MORE BEACUSE NOW CYCLES
         cat $count".dat" | cut -d, -f1,2 > temp; mv temp $count".dat"         
         paste *.dat  energy.avg -d "," > $OUTPUT_FILE_NAME
         rm *.dat

         #IF YOU WANT TO NORMALIZE, COMMENT ALL 5 INSTRUCTIONS BELOW
         #This line will collect all cycles for calculate the average
         cat $OUTPUT_FILE_NAME | awk '{printf "%.6f\n", ($1+$6+$12+$17+$22+$27+$32+$37+$42)/9}' > cycles.avg
         #Here we removed all cycles 
         cut -d, -f1,5,11,16,21,26,31,36,41 --complement $OUTPUT_FILE_NAME > temp
         mv temp $OUTPUT_FILE_NAME
         paste cycles.avg $OUTPUT_FILE_NAME -d "," > temp
         mv temp $OUTPUT_FILE_NAME

         #remove the first two lines and the last two lines
         num_lines=`cat $OUTPUT_FILE_NAME |wc -l`
         x=$((num_lines-2)) 
         sed -e "$x,\$d" $OUTPUT_FILE_NAME > temp1
         sed -e "1,2d" temp1 > temp2       
         mv temp2 $OUTPUT_FILE_NAME
         rm temp*      
         #remove lines have..nan 
         sed -i '/-nan/d' $OUTPUT_FILE_NAME
         sed -i '/nan/d' $OUTPUT_FILE_NAME  

     elif [ $1 = "big" ]; then
         OUTPUT_FILE_NAME="consolidated-pmc-big.csv"
         count=-1
         files=`ls *.csv` #cada csv possui 4 pmcs
         for file in $files ;
         do
             count=$(($count + 1))   
             #echo "Normalize file:"$file" out will be:"$count".dat"
             cat $file | awk -F "," '{printf "%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n", $2,$3,$4,$5,$6,$7,$8}' > $count".dat"                   
         done
 
         #If you want to normalize, just cut -f1,2
         #the last file just have two pmcs, the other four are null. But it was necessary add ONE MORE BEACUSE NOW CYCLES
         cat $count".dat" | cut -d, -f1,2,3 > temp; mv temp $count".dat" 
         paste *.dat  energy.avg -d "," > $OUTPUT_FILE_NAME
         rm *.dat

         cat $OUTPUT_FILE_NAME | awk '{printf "%.6f\n", ($1+$6+$12+$17+$22+$27+$32+$37+$42+$47)/10}' > cycles.avg
         cut -d, -f1,5,11,16,21,26,31,36,41,49 --complement $OUTPUT_FILE_NAME > temp
         mv temp $OUTPUT_FILE_NAME
         paste cycles.avg $OUTPUT_FILE_NAME -d "," > temp
         mv temp $OUTPUT_FILE_NAME

         #remove the first two lines and the last two lines
         num_lines=`cat $OUTPUT_FILE_NAME |wc -l`
         x=$((num_lines-2)) 
         sed -e "$x,\$d" $OUTPUT_FILE_NAME > temp1
         sed -e "1,2d" temp1 > temp2       
         mv temp2 $OUTPUT_FILE_NAME
         rm temp*      
         #remove lines have..nan 
         sed -i '/-nan/d' $OUTPUT_FILE_NAME
         sed -i '/nan/d' $OUTPUT_FILE_NAME  

     else
          echo "You need pass as argument cluster name: big or little"
          read -p "Press enter to exit!"
          exit 1
     fi            
}



restart_script
gather_energy_measurements
check_stdev_energy_files

#utiliza o script que junta os pmcs em um único arquivo
FOLDERS=`ls -d 4b_* 4b4l_A15*`
for i in $FOLDERS ;
do  
    cd $i
    echo $i
    map_pmcs_to_energy "big"
    create_dataset "big"
    cd .. ; 
    #read -p "check!"
done


FOLDERS=`ls -d 4l_* 4b4l_A7*`
for i in $FOLDERS ;
do  
    cd $i
    echo $i
    map_pmcs_to_energy "little"
    create_dataset "little"   
    cd .. ; 
    #read -p "check!"
done


#create dataset
cat 4l_*/consolidated-pmc-little.csv | awk -F "," '{print}' >> 4l.csv
cat 4b_*/consolidated-pmc-big.csv | awk -F "," '{print}' >> 4b.csv
cat 4b4l_A7_*/consolidated-pmc-little.csv | awk -F "," '{print}' >> 4b4l_A7.csv
cat 4b4l_A15_*/consolidated-pmc-big.csv | awk -F "," '{print}' >> 4b4l_A15.csv

sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,power' 4l.csv
sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,power' 4b4l_A7.csv
sed  -i '1i CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x71,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power' 4b.csv
sed  -i '1i CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x71,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power' 4b4l_A15.csv




#This script just join dataset 4b4l_A7.txt and 4b4l_A15.txt.
#So, before execute this script, you need to get those datasets.
rm -f *.txt *energy
cat 4b4l_A7.csv | wc -l > A7.lines
cat 4b4l_A15.csv | wc -l > A15.lines

#Get the last column
cat 4b4l_A7.csv | awk -F, '{print $(NF)}' > Energy_A7
cat 4b4l_A15.csv | awk -F, '{print $(NF)}' > Energy_A15  

sed -i '1d' Energy_A7
sed -i '1d' Energy_A15

paste Energy_A7 Energy_A15 -d "," > all_energy
cat all_energy | tr "," "\t" | awk '{printf "%.2f\n", ($1+$2)/2}' > average_energy.txt
sed -i '1s/^/power\n/' average_energy.txt


awk -F, '{$NF=""; print $0}' 4b4l_A7.csv | tr " " "," > Features_A7.txt
awk -F, '{$NF=""; print $0}' 4b4l_A15.csv | tr " " "," > Features_A15.txt

NUM_LINHAS_COMUM=10000000
FILES=$(ls *.lines)      
for i in $FILES;
do  
	atual=$(cat $i)
	if [ $atual -lt $NUM_LINHAS_COMUM ]
	then
	    NUM_LINHAS_COMUM=$atual
	fi
done	       

#remove as linhas que não são comum a todos
sed -i -n "1,$NUM_LINHAS_COMUM p" *.txt

paste Features_A7.txt Features_A15.txt average_energy.txt -d "" > 4b4l.csv
rm -f Energy_* *.lines Features* average* all_energy

./2_postprocess_create_dataset_power_multitarget.sh
