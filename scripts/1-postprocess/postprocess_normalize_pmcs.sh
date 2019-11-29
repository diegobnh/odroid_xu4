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

	   #calculates pmcs normalizing by CYCLES
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

	   #calculates pmcs normalizing by CYCLES
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
                
else
   echo "You need pass as argument cluster name: big or little"
   read -p "Press enter to exit!"
   exit 1
fi

#cada aplicação terá um exec_time.average
#O datamash na versão do arm faz as operações usando "ponto". Então esse código não vai funcionar no arm.
cat times.txt | tr "." "," | datamash mean 1 | tr "," "." > exec_time.average

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
