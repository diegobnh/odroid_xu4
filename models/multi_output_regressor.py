import sys
import numpy as np 
import pandas as pd
from joblib import *
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.neighbors import KNeighborsRegressor
from sklearn.metrics import r2_score


fileName = sys.argv[1]
core = sys.argv[2]
#model_name = sys.argv[3]

if core == 'big':
   select_features=['L1D_CACHE_INVAL:0x48','VPF_SPEC:0x75','MEM_ACCESS_ST:0x67','L1D_CACHE_WB_VICTIM:0x46','UNALIGNED_LDST_SPEC:0x6A','L1I_CACHE_REFILL:0x01','speedup4l','speedup4b','speedup4b4l']

elif core == 'little':
   select_features=['data_snooped','data_cache_evic', 'inst_fetch_tlb_refill', 'branch_predic','speedup4l', 'speedup4b','speedup4b4l']
   
elif core == 'biglittle':
   select_features= ['data_cache_evic','data_read_write_cache_access','bus_cycle','no_cache_ext_mem_req','L1D_CACHE_INVAL:0x48','L1D_CACHE_WB_VICTIM:0x46','L2D_CACHE_ACCESS:0x16','DP_SPEC:0x73','L1I_CACHE_REFILL:0x01','L1D_CACHE_WB_CLEAN:0x47','speedup4l', 'speedup4b','speedup4b4l']

else:
   print("Entrada invalida!!")


dataframe = pd.read_csv(fileName)
df = dataframe[select_features]


df_X = df.iloc[:, 0:(len(df.columns) - 3)]
df_Y = df.iloc[:, len(df.columns) - 3: len(df.columns)] 


X = df_X.values
Y = df_Y.values

models= [("Decision_Tree_Regressor", DecisionTreeRegressor(max_depth=9)), #random_state=0,
         ('KNN_Regressor', KNeighborsRegressor(n_neighbors=2)),              
         ("Random_Forest_Regressor", RandomForestRegressor(n_estimators=550, n_jobs=-1)) #random_state=0,
        ]

for name, model in models:
   model = model
   model.fit(X, Y)
   Y_pred = model.predict(X)

   print(name, " R2:",r2_score(Y, Y_pred))
   output=name+"_"+core+".pkl"
   dump(model, output)

'''

#TEST LOAD MODEL
model = load(model_name)
X = df.values
print(len(X))
for i in range(len(X)):
    result = model.predict([X[i]])
    print(result[0])
'''

