#!/bin/bash

printf "This script use other script responsible to create consolidate.csv file for each config and each application. \n"
read -p "Press enter in case already executed it before.."

#Essa ordem é importante pois o plot assume ordem igual
APPS=("fib" "nqueens" "health" "floorplan" "fft" "sort" "sparselu" "strassen")

#A primeira coisa a ser feita é descobrir para cada aplicação, qual configuração teve o menor tempo. 
#Após isso, todas as outras confgurações deverá ter relação igual ou superior a 1. Essa relação será armazenada na variável "tics"

for ((j = 0; j < ${#APPS[@]}; j++));
do   
       echo ${APPS[$j]} 
       NUM_LINHAS_COMUM=$(wc -l *${APPS[$j]}/consolidate* | awk '{print $1}' | datamash min 1)

       folders=$(ls -d *${APPS[$j]})
       for i in $folders ;
       do
          rm -f consolidate.tics               
          cd $i;          
                  current=$(wc -l consolidate* | awk '{print $1}')
                  result=$(echo "scale=1; $current / $NUM_LINHAS_COMUM" | bc)
                  tics=`/usr/bin/printf "%.0f" $result` #Round to up or down
                  
                  num_columns=$(cat consolidate* | awk -F',' '{print NF; exit}')
                  for num in $(seq 1 $num_columns);     
                  do                                    
                        cat consolidate* | awk -F "," -v col=$num  "{sum += (\$col); if (NR % $tics == 0) {print (sum/$tics); sum=0}}" > $num".diego"                              
                  done
          cd ..          
       done
done

#Devido a uma aproximação na variável tics, os arquivos finais poderão ter um número de linhas menor do que foi calculado anteriormente.
#Por isso, mais uma vez devemos igualar o número de linhas a configuração que está com o menor número de linhas.

for ((j = 0; j < ${#APPS[@]}; j++));
do   
       NUM_LINHAS_COMUM=$(wc -l *${APPS[$j]}/1.diego | awk '{print $1}' | datamash min 1)
       folders=$(ls -d *${APPS[$j]})
       for i in $folders ;
       do          
          cd $i;  
          paste -d, $(ls -v *.diego) > pmcs.tics
          sed -n "1,$NUM_LINHAS_COMUM p" pmcs.tics > aux
          mv aux pmcs.tics
          rm *.diego
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
cat 4l.aux | awk -F "," '{printf "%.2f\n", $NF}' > 4l_target.aux
cat 4b.aux | awk -F "," '{printf "%.2f\n", $NF}' > 4b_target.aux
cat 4b4l_A7.aux | awk -F "," '{printf "%.2f\n", $NF}' > 4b4l_A7_target.aux
cat 4b4l_A15.aux | awk -F "," '{printf "%.2f\n", $NF}' > 4b4l_A15_target.aux
paste -d "," 4b4l_A7_target.aux 4b4l_A15_target.aux | awk -F "," '{printf "%.2f\n", ($1+$2)*0.50}' > 4b4l_target.aux

#Gerando o target a ser incluido em todoso os files
paste -d "," 4l_target.aux 4b_target.aux 4b4l_target.aux > columns_target 

#Obtendo os pmcs sem o power
cat 4l.aux | awk -F, 'NF-=1' | tr " " "," > 4l_temp.aux
cat 4b.aux | awk -F, 'NF-=1' | tr " " "," > 4b_temp.aux
cat 4b4l_A7.aux | awk -F, 'NF-=1' | tr " " "," > 4b4l_A7_temp.aux
cat 4b4l_A15.aux | awk -F, 'NF-=1' | tr " " "," > 4b4l_A15_temp.aux

#Adicionando os targets para cada arquivo
paste -d "," 4l_temp.aux columns_target > 4l_multitarget.csv
paste -d "," 4b_temp.aux columns_target > 4b_multitarget.csv
paste -d "," 4b4l_A7_temp.aux columns_target > 4b4l_A7_multitarget.csv
paste -d "," 4b4l_A15_temp.aux columns_target > 4b4l_A15_multitarget.csv

cat 4b4l_A7_multitarget.csv | awk -F, 'NF-=3' | tr " " "," > 4b4l_temp.aux
paste -d "," 4b4l_temp.aux 4b4l_A15_multitarget.csv > 4b4l_multitarget.csv

sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,power4l,power4b,power4b4l' 4l_multitarget.csv
sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,power4l,power4b,power4b4l' 4b4l_A7_multitarget.csv
sed  -i '1i CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power4l,power4b,power4b4l' 4b_multitarget.csv
sed  -i '1i CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power4l,power4b,power4b4l' 4b4l_A15_multitarget.csv
sed  -i '1i cycles:0x11,inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,CYCLES:0x11,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,power4l,power4b,power4b4l' 4b4l_multitarget.csv

rm -f *.aux
