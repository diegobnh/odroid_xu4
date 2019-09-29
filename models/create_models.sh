#!/bin/bash

python3 multi_output_regressor.py dataset/bots/4l.csv little
python3 multi_output_regressor.py dataset/bots/4b.csv big
python3 multi_output_regressor.py dataset/bots/4b4l.csv biglittle

#python3 multi_output_regressor.py dataset/rodinia/4l.csv little
#python3 multi_output_regressor.py dataset/rodinia/4b.csv big
#python3 multi_output_regressor.py dataset/rodinia/4b4l.csv biglittle
rm models/*.pkl
mv *.pkl models/
