#!/bin/sh

#Esse script deve estar junto com as pastas referente aos outputs. Deixe apenas as pastas e remove os arquivos comprimidos.

#Para descomprimir todas as pastas execute o comando abaixo:
#cat *.tar | tar -xf - -i

#Alterado para a proposta de multioutput regressor.Por isso, apenas um arquivo para cada configuração será gerado.
#A saida será todos os performance counter como média e três colunas ao final que se refere ao speedup no 4l, 4b, 4b4l. 




rm -f -- *.csv
#remove files existentes
FOLDERS=`ls -d */`
for i in $FOLDERS ;
do  
    cd $i; 
    if [ -f times.txt ]; then
       rm times.txt
    fi
    cd ..
done
    

#utiliza o script que junta os pmcs em um único arquivo
FOLDERS=`ls -d 4b_* 4b4l_A15*`
for i in $FOLDERS ;
do  
    cd $i
    echo "4b4l_A15 Folder:"$i
    bash ../postprocess_experiment.sh "big"
    cat times.txt | tr "." "," | datamash sstdev 1 > temp
    cat temp | awk -v app="$i" '{print "standard deviation time:",$1,"App:", app}' > desv
    cd .. ; 
done


FOLDERS=`ls -d 4l_* 4b4l_A7*`
for i in $FOLDERS ;
do  
    cd $i
    echo "4b4l_A7 Folder:"$i
    bash ../postprocess_experiment.sh "little"       
    cat times.txt | tr "." "," | datamash sstdev 1 > temp
    cat temp | awk -v app="$i" '{print "standard deviation time:",$1,"App:", app}' > desv
    cd .. ; 
done


#After calculate the average,confirm if the results are corrects using the command below:
#cat 4b4l_A7*/consolidated-pmc-little.csv.average
#cat 4b4l_A15*/consolidated-pmc-little.csv.average

echo ""
cat */desv

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






#------------------------------
#Calculate dataset for 4little
#------------------------------
FOLDERS=`ls -d 4l_*`
for i in $FOLDERS ;
do  
    cd $i 
    #cat consolidated-pmc-little.csv.average | tr "," " " | awk '{$34=""; print}' | tr " " "," >> ../4l.csv
    cat consolidated-pmc-little.csv.average | tr "," " " | awk '{print}' | tr " " "," >> ../4l.csv
    cd ..    
done

cat speedup_4l | tr "," " " | awk  '{print $2}' > to_4b4l
cat speedup_4l | tr "," " " | awk  '{print $1}' > to_4b

awk '$0=$0",1"' 4l.csv > temp #add 1 última coluna
paste temp to_4b to_4b4l -d "," > 4l.csv
rm to_* 

#--------------------------
#Calculate dataset for 4big
#--------------------------

FOLDERS=`ls -d 4b_*`
for i in $FOLDERS ;
do  
    cd $i 
    #cat consolidated-pmc-big.csv.average | tr "," " " | awk '{$57=""; print}' | tr " " "," >> ../4b.csv
    cat consolidated-pmc-big.csv.average | tr "," " " | awk '{print}' | tr " " "," >> ../4b.csv
    cd ..    
done

cat speedup_4b | tr "," " " | awk  '{print $2}' > to_4b4l
cat speedup_4b | tr "," " " | awk  '{print $1}' > to_4l
paste 4b.csv to_4l -d "," > temp1
awk '$0=$0",1"' temp1 > temp2
paste temp2 to_4b4l -d "," > 4b.csv
rm to_*  


#--------------------------
#Calculate dataset for 4b4l
#--------------------------
FOLDERS=`ls -d 4b4l_A15*`
for i in $FOLDERS ;
do  
    cd $i     
    #cat consolidated-pmc-big.csv.average | tr "," " " | awk '{$57=""; print}' | tr " " "," >> ../average_samples_A15
    cat consolidated-pmc-big.csv.average | tr "," " " | awk '{print}' | tr " " "," >> ../average_samples_A15
    cd ..    
done

FOLDERS=`ls -d 4b4l_A7*`
for i in $FOLDERS ;
do  
    cd $i     
    #cat consolidated-pmc-little.csv.average | tr "," " " | awk '{$34=""; print}' | tr " " "," >> ../average_samples_A7
    cat consolidated-pmc-little.csv.average | tr "," " " | awk '{print}' | tr " " "," >> ../average_samples_A7
    cd ..    
done

cat speedup_4b4l | tr "," " " | awk '{print $2}' > to_4b
cat speedup_4b4l | tr "," " " | awk '{print $1}' > to_4l

paste average_samples_A7 average_samples_A15 -d "," > 4b4l.csv
paste 4b4l.csv to_4l to_4b -d "," > temp
awk '$0=$0",1"' temp > 4b4l.csv


rm to_* average_samples_* temp*



sed -i 's/,,/,/g' 4l.csv
sed -i 's/,,/,/g' 4b.csv
sed -i 's/,,/,/g' 4b4l.csv

rm speedup*

sed -i '1s/^/L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,speedup4l,speedup4b,speedup4b4l \n/' 4b.csv
sed -i '1s/^/inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,speedup4l,speedup4b,speedup4b4l \n/' 4l.csv
sed -i '1s/^/inst_fetch_refill:0x01,inst_fetch_tlb_refill:0x02,data_rw_refill:0x03,data_rw_cache_access:0x04,data_rw_tlb_refill:0x05,data_read_exec:0x06,data_write_exec:0x07,ins_exec:0x08,excep_taken:0x09,excep_exec:0x0A,change_pc:0x0C,imed_branch_exec:0x0D,proc_return:0x0E,un_load_store:0x0F,br_pred:0x10,branches:0x12,data_mem_access:0x13,inst_cache_access:0x14,dcache_evic:0x15,l2d_cache_access:0x16,l2d_cache_refill:0x17,l2d_cache_write:0x18,bus_access:0x19,bus_cycle:0x1D,bus_access_read:0x60,bus_access_write:0x61,ext_mem_req:0xC0,no_cache_ext_mem_req:0xC1,enter_read_alloc_mode:0xC4,read_alloc_mode:0xC5,reserved:0xC6,data_w_stalls:0xC9,data_snooped:0xCA,L1I_CACHE_REFILL:0x01,L1I_TLB_REFILL:0x02,L1D_CACHE_REFILL:0x03,L1D_CACHE_ACCESS:0x04,L1D_TLB_REFILL:0x05,INSTR_RETIRED:0x08,EXC_TAKEN:0x09,BR_MIS_PRED:0x10,BR_PRED:0x12,MEM_ACCESS:0x13,L1I_CACHE_ACCESS:0x14,L1D_CACHE_WB:0x15,L2D_CACHE_ACCESS:0x16,L2D_CACHE_REFILL:0x17,L2D_CACHE_WB:0x18,BUS_ACCESS:0x19,INST_SPEC:0x1B,BUS_CYCLES:0x1D,L1D_CACHE_LD:0x40,L1D_CACHE_ST:0x41,L1D_CACHE_REFILL_LD:0x42,L1D_CACHE_REFILL_ST:0x43,L1D_CACHE_WB_VICTIM:0x46,L1D_CACHE_WB_CLEAN:0x47,L1D_CACHE_INVAL:0x48,L1D_TLB_REFILL_LD:0x4C,L1D_TLB_REFILL_ST:0x4D,L2D_CACHE_LD:0x50,L2D_CACHE_ST:0x51,L2D_CACHE_REFILL_LD:0x52,L2D_CACHE_REFILL_ST:0x53,L2D_CACHE_WB_VICTIM:0x56,L2D_CACHE_INVAL:0x58,BUS_ACCESS_LD:0x60,BUS_ACCESS_ST:0x61,BUS_ACCESS_SHARED:0x62,BUS_ACCESS_NORMAL:0x64,MEM_ACCESS_LD:0x66,MEM_ACCESS_ST:0x67,UNALIGNED_LD_SPEC:0x68,UNALIGNED_ST_SPEC:0x69,UNALIGNED_LDST_SPEC:0x6A,LDREX_SPEC:0x6C,STREX_PASS_SPEC:0x6D,STREX_FAIL_SPEC:0x6E,LD_SPEC:0x70,ST_SPEC:0x70,LDST_SPEC:0x72,DP_SPEC:0x73,ASE_SPEC:0x74,VFP_SPEC:0x75,PC_WRITE_SPEC:0x76,BR_IMMED_SPEC:0x78,BR_RETURN_SPEC:0x79,BR_INDIRECT_SPEC:0x7A,DMB_SPEC:0x7E,speedup4l,speedup4b,speedup4b4l \n/' 4b4l.csv

