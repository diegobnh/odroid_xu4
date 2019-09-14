#!/bin/sh


if [ $1 = "little" ]; then
	OUTPUT_FILE_NAME="consolidated-pmc-little.csv"

	[ -e $OUTPUT_FILE_NAME ] && rm $OUTPUT_FILE_NAME

	files=`ls *.csv` #cada csv possui 4 pmcs
	for file in $files ;
	do 
           #obtém só o nome do folder sem a barra
	   pmcs=${file%.csv}

           #1º calcula o tempo 
           cat $file | awk 'END{print $1}' | tr "," " " | awk '{print $1*0.001}' >> times.txt
           wc -l $file | awk '{print $1}' >> num_lines.txt
           
	   #remove the first two lines and the last two lines
	   num_lines=`cat $file |wc -l`
	   x=$((num_lines-2)) 
	   sed -e "$x,\$d" $file > temp1
	   sed -e "1,2d" temp1 > temp2
	   
	   #remove the time column and the columns software counters and utilization
	   cat temp2 | tr "," " " | awk '{$1=$7=$8=$9=$10=""; print}' > temp3 #Toda vez que você omite uma impressão ele coloca espaços em branco que removem o padrão do arquiv. Por isso precisa usar printf depois

	   #calculates pmcs normalizing by instructions
	   cat temp3 | awk '{printf "%.6f,%.6f,%.6f,%.6f\n", $2/$1, $3/$1, $4/$1, $5/$1}' > $pmcs".post_process"	
           sed -i '/-nan/d' $pmcs".post_process"
           sed -i '/nan/d' $pmcs".post_process"  

	   #save the num_lines
	   cat $pmcs".post_process" | wc -l  > $pmcs".lines"

	   rm temp*

	done

              
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
	sed -i -n "1,$NUM_LINHAS_COMUM p" *.post_process

        #Só depois que todos possuem o mesmo número de linhas que se faz a junção. NÃO ESQUEÇA DISSO!
        paste *.post_process -d "," > $OUTPUT_FILE_NAME

        rm *.lines

        
        #remove coluns in range 34-36 -> last 3 columns are null
        cut -d, -f34-36 --complement $OUTPUT_FILE_NAME > temp
        mv temp $OUTPUT_FILE_NAME

       	#add new line with subtitle for each column	
        #sed -i -e 'inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA\' $OUTPUT_FILE_NAME
        
elif [ $1 = "big" ]; then
	OUTPUT_FILE_NAME="consolidated-pmc-big.csv"

	[ -e $OUTPUT_FILE_NAME ] && rm $OUTPUT_FILE_NAME
       
	files=`ls *.csv`
	for file in $files ;
	do  
      	   pmcs=${file%.csv}

           cat $file | awk 'END{print $1}' | tr "," " " | awk '{print $1*0.001}' >> times.txt
           wc -l $file | awk '{print $1}' >> num_lines.txt


	   #remove the first two lines and the last two lines
	   num_lines=`cat $file |wc -l`
	   x=$((num_lines-2)) 
	   sed -e "$x,\$d" $file > temp1
	   sed -e "1,2d" temp1 > temp2
	   
	   #remove the time column and the columns 9,10,11,12 that means cluster utilization and software counters
	   cat temp2 | tr "," " " | awk '{$1=$9=$10=$11=$12=""; print}' > temp3

	   #calculates pmcs normalizing by instructions
	   cat temp3 | awk '{printf "%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n", $2/$1, $3/$1, $4/$1, $5/$1, $6/$1, $7/$1}' > $pmcs".post_process"
           #division 0 per 0 result values -nan. I just remove theses lines. Sometimes cycles and others counters are zero
           sed -i '/-nan/d' *.post_process
           sed -i '/nan/d' *.post_process	  
	   
	   #save the num_lines
	   cat $pmcs".post_process" | wc -l  > $pmcs".lines"

	   rm temp*

	done

       

	NUM_LINHAS_COMUM=1000000
	FILES=$(ls *.lines)      
	for i in $FILES;
	do  
		atual=$(cat $i)
		if [ $atual -lt $NUM_LINHAS_COMUM ]
		then
		    NUM_LINHAS_COMUM=$atual
		fi
	done	       
	  
	rm *.lines

        #remove as linhas que não são comum a todos
	sed -i -n "1,$NUM_LINHAS_COMUM p" *.post_process

        #Só depois que todos possuem o mesmo número de linhas que se faz a junção. NÃO ESQUEÇA DISSO!
        paste *.post_process -d "," > $OUTPUT_FILE_NAME


        #remove coluns in range 57-60 -> last 4 columns are null
        cut -d, -f57-60 --complement $OUTPUT_FILE_NAME > temp
        mv temp $OUTPUT_FILE_NAME
        
	#add new line with subtitle for each column	
        #sed -i -e 'L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0X4C,L1D_TLB_REFILL_ST:0X4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0X67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E\' $OUTPUT_FILE_NAME

        
else
   echo "You need pass as argument cluster name: big or little"
   read -p "Press enter to exit!"
   exit 1
fi


#cada aplicação terá um exec_time.average
cat times.txt | datamash mean 1 | tr "," "." > exec_time.average


#Calculate the average for each feature 
if [ $1 = "little" ]; then
   #o sed remove a primeira linha que possui o nome de cada coluna
   #sed 1d $OUTPUT_FILE_NAME | tr "," "\t" | tr "." "," | datamash mean 1-33 | tr "," "." | tr "\t" "," > $OUTPUT_FILE_NAME".average"
   cat $OUTPUT_FILE_NAME | tr "," "\t" | tr "." "," | datamash mean 1-33 | tr "," "." | tr "\t" "," > $OUTPUT_FILE_NAME".average"
   #paste temp exec_time.average -d "," >  $OUTPUT_FILE_NAME".average"


elif [ $1 = "big" ]; then 
   #sed 1d $OUTPUT_FILE_NAME | tr "," "\t" | tr "." "," | datamash mean 1-56 | tr "," "." | tr "\t" "," > $OUTPUT_FILE_NAME".average"
   cat $OUTPUT_FILE_NAME | tr "," "\t" | tr "." "," | datamash mean 1-56 | tr "," "." | tr "\t" "," > $OUTPUT_FILE_NAME".average"
   #paste temp exec_time.average -d "," >  $OUTPUT_FILE_NAME".average"
fi

rm *.post_process 
#read -p "Check the files TIMES and NUM_LINES before the delete.."
rm num_lines.txt #exec_time.average #times.txt
