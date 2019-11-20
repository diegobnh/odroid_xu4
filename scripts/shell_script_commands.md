**Agrupamento**

- shell script

cat consolidate* | awk  "{sum += (\$NF); if (NR % $tics == 0) {print (sum/$tics); sum=0}} " > pmcs.tics (pega a última coluna - NF - e calcula a média para cada $tics linhas)

- datamash

cat $file | datamash -s -g 1 mean 2-6 (agrupar os timestamps da coluna 1 e calcular a média para as outras colunas desse agrupamento)

**Operações ponto flutuante**

- divisão(sem arredondamento)

result=$(echo "scale=1; $current / $NUM_LINHAS_COMUM" | bc)

- arredondamento

tics=`/usr/bin/printf "%.0f" $result` #Round to up or down

**Operações de impressão/remoção linhas**

- remoção de todas as linhas superiores a um valor X

sed -n "1,$NUM_LINHAS_COMUM p" pmcs.tics > aux

- remoção das primeiras e das últimas n linhas

num_lines=`cat $file |wc -l`
x=$((num_lines-2)) 
sed -e "$x,\$d" $file > temp1
sed -e "1,2d" temp1 > temp2

**Operações de remoção de colunas**

- remover as últimas 3 colunas

cut -d, -f34-36 --complement $OUTPUT_FILE_NAME > temp

**Loops**

- usando uma variable como contorle do laço

num_coluns=$(cat consolidate* | awk -F',' '{print NF; exit}')
for num in $(seq 1 $num_columns);     
do  
done

**awk**

- usando variáveis

cat temp | awk -v app="$i" '{print "standard deviation time:",$1,"App:", app}' > desv


- não imprimir determinadas colunas

cat temp2 | tr "," " " | awk '{$1=$9=$10=$11=$12=""; print}' > temp3

- contando número de colunas de um arquivo

cat consolidated-pmc-little.csv | awk -F',' '{print NF; exit}'

**Files**
- percorrer todos os files com um padrão

FILES=$(ls *.lines)      
for i in $FILES;
do  

done

- obter apenas o nome do arquivo sem extensão

FILES=$(ls *.lines)      
for i in $FILES;
do  
     name=${file%.csv}
done

- remover file e, caso não exista, omitir o warning

rm -f *.csv 

**Folders**

- percorrer determinados folders

FOLDERS=`ls -d 4l_* 4b4l_A7*`
for i in $FOLDERS ;
do
    cd $i;          
    #python3 ../plot_energy.py 9      
    cd ..;
done

ou

APPS=("fib" "nqueens" "health" "floorplan" "fft" "sort" "sparselu" "strassen")

for ((j = 0; j < ${#APPS[@]}; j++));
do   
      folders=$(ls -d *${APPS[$j]}) #lista todos os folders com o nome da aplicação
      for i in $folders ;
      do          
         cd $i;  
         cd ..    
      done
done

