#!/bin/sh

#Esse script deve estar junto com as pastas referente aos outputs. E o script postprocess deve estar um diretório acima.

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
    bash ../../postprocess_experiment.sh "big"
    cat times.txt | tr "." "," | datamash sstdev 1 > desv
    cd .. ; 
done


FOLDERS=`ls -d 4l_* 4b4l_A7*`
for i in $FOLDERS ;
do  
    cd $i
    echo "4b4l_A7 Folder:"$i
    bash ../../postprocess_experiment.sh "little"       
    cat times.txt | tr "." "," | datamash sstdev 1 > desv
    cd .. ; 
done


#After calculate the average,confirm if the results are corrects using the command below:
#cat 4b4l_A7*/consolidated-pmc-little.csv.average
#cat 4b4l_A15*/consolidated-pmc-little.csv.average

echo ""
cat */desv
read -p "Veja se alguma aplicação possui um desvio padrão alto(>3). Se tiver, altere a media na mão."


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
FOLDERS=`ls -d 4l_bots*`
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

FOLDERS=`ls -d 4b_bots*`
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
#7 primeiras colunas nulas seguida de 5 colunas com valores, mais três colunas referentes a performance no tempo
#cat 4l.csv | tr ',' '\t' | awk '{printf "%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n", 0,0,0,0,0,0,0,$1,$3,$5,$7,$9,$34,$35,$36}' > temp1
#7 primeiras colunas com valores seguida de 5 colunas nulas, mais três colunas referentes a performance no tempo
#cat 4b.csv | tr ',' '\t' | awk '{printf "%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n", $1,$3,$5,$7,$9,$11,$13,0,0,0,0,0,$57,$58,$59}' > temp2 
#não há coluna nula na config 4b4l
#cat 4b4l.csv | tr ',' '\t' | awk '{printf "%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n", $1,$3,$5,$7,$9,$11,$13,$1,$3,$5,$7,$9, $89,$90,$91}' > temp3

#cat *.csv > dataset.csv


