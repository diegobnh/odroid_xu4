import sys
import numpy as np 
import pandas as pd
from joblib import *
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.neighbors import KNeighborsRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.metrics import r2_score


fileName = sys.argv[1]
core = sys.argv[2]
#model_name = sys.argv[3]

if core == 'little':
   #select_features=['data_snooped:0xCA','dcache_evic:0x15', 'inst_fetch_tlb_refill:0x02', 'branches:0x12','speedup4l', 'speedup4b','speedup4b4l']
   #select_features=['data_snooped:0xCA','inst_fetch_tlb_refill:0x02','data_rw_refill:0x03','un_load_store:0x0F','speedup4l','speedup4b','speedup4b4l']
   select_features=['data_snooped:0xCA','dcache_evic:0x15','br_pred:0x10','read_alloc_mode:0xC5','speedup4l','speedup4b','speedup4b4l']

elif core == 'big':
   #select_features=['L1D_CACHE_INVAL:0x48','VFP_SPEC:0x75','MEM_ACCESS_ST:0X67','L1D_CACHE_WB_VICTIM:0x46','UNALIGNED_LDST_SPEC:0x6A','L1I_CACHE_REFILL:0x01','speedup4l','speedup4b','speedup4b4l']
   #select_features=['L1D_CACHE_WB_CLEAN:0x47','LDREX_SPEC:0x6C','VFP_SPEC:0x75','MEM_ACCESS_ST:0X67','BUS_ACCESS_NORMAL:0x64','L1D_CACHE_INVAL:0x48','speedup4l','speedup4b','speedup4b4l']
   select_features=['LDREX_SPEC:0x6C','DMB_SPEC:0x7E','L2D_CACHE_LD:0x50','L1D_CACHE_WB_CLEAN:0x47','UNALIGNED_ST_SPEC:0x69','VFP_SPEC:0x75','speedup4l','speedup4b','speedup4b4l']

elif core == 'biglittle':
   #select_features=['dcache_evic:0x15','data_rw_cache_access:0x04','bus_cycle:0x1D','no_cache_ext_mem_req:0xC1','L1D_CACHE_INVAL:0x48','L1D_CACHE_WB_VICTIM:0x46','L2D_CACHE_ACCESS:0x16','DP_SPEC:0x73','L1I_CAC$
   #select_features=['dcache_evic:0x15','data_read_exec:0x06','bus_cycle:0x1D','l2d_cache_write:0x18','L1D_CACHE_INVAL:0x48','L1D_CACHE_WB_CLEAN:0x47','L2D_CACHE_ACCESS:0x16','L2D_CACHE_ST:0x51','L1D_CACHE_WB_V$
   select_features=['bus_cycle:0x1D','data_rw_refill:0x03','un_load_store:0x0F','l2d_cache_write:0x18','MEM_ACCESS_ST:0X67','L2D_CACHE_LD:0x50','L1D_CACHE_ST:0x41','L1D_CACHE_WB_CLEAN:0x47','L1D_CACHE_WB_VICTIM$
else:
   print("Entrada invalida!!")


dataframe = pd.read_csv(fileName)
df = dataframe[select_features]

df_X = df.iloc[:, 0:len(df.columns)-3]
df_Y = df.iloc[:, len(df.columns)-3: len(df.columns)] 

X = df_X.values
Y = df_Y.values

models= [("Decision_Tree_Regressor", DecisionTreeRegressor(max_depth=9)), #random_state=0,
         ('KNN_Regressor', KNeighborsRegressor(n_neighbors=2)),              
         ("Random_Forest_Regressor", RandomForestRegressor(n_estimators=550, n_jobs=-1)), #random_state=0,
         ("Neural_Network", MLPRegressor(hidden_layer_sizes=(500,300,150),alpha=0.01, batch_size=16,max_iter=10000, activation='relu', solver='adam', learning_rate='adaptive'))
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

