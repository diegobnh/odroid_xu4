#!/bin/bash
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
