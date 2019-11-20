**Agrupamento**

- shell script

cat consolidate* | awk  "{sum += (\$NF); if (NR % $tics == 0) {print (sum/$tics); sum=0}} " > pmcs.tics (pega a última coluna - NF - e calcula a média para cada $tics linhas)

- datamash

cat $file | datamash -s -g 1 mean 2-6 (agrupar os timestamps da coluna 1 e calcular a média para as outras colunas desse agrupamento)
