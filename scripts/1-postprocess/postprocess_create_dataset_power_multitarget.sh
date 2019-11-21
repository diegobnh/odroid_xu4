#!/bin/bash

read -p "This script use other script responsible to create consolidate.csv file for each config and each application. Press enter in case already executed it before"

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
cat 4l.aux | awk -F "," '{print $NF}' > 4l_target.aux
cat 4b.aux | awk -F "," '{print $NF}' > 4b_target.aux
cat 4b4l_A7.aux | awk -F "," '{print $NF}' > 4b4l_A7_target.aux
cat 4b4l_A15.aux | awk -F "," '{print $NF}' > 4b4l_A15_target.aux
paste -d "," 4b4l_A7_target.aux 4b4l_A15_target.aux | awk -F "," '{print ($1+$2)*0.50}' > 4b4l_target.aux

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

rm -f *.aux
