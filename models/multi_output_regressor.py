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


if core == 'little':
   #filter method
   #select_features=['br_pred:0x10','inst_fetch_tlb_refill:0x02','un_load_store:0x0F','data_rw_refill:0x03','speedup4l','speedup4b','speedup4b4l'] //pmcs bots
   #select_features=['bus_access_write:0x61','reserved:0xC6','br_pred:0x10','inst_cache_access:0x14','speedup4l','speedup4b','speedup4b4l'] #pmcs rodinia

   #wrapper method
   #select_features=['data_snooped:0xCA','read_alloc_mode:0xC5','inst_fetch_tlb_refill:0x02','change_pc:0x0C','speedup4l','speedup4b','speedup4b4l'] #pmcs bots
   select_features=['bus_access:0x19','data_read_exec:0x06', 'data_write_exec:0x07', 'ext_mem_req:0xC0','speedup4l','speedup4b','speedup4b4l'] #pmcs rodinia


elif core == 'big':
   #filter method
   #select_features=['L2D_CACHE_REFILL_ST:0x53','L1D_TLB_REFILL_ST:0x4D','L1D_CACHE_INVAL:0x48','VFP_SPEC:0x75','BR_INDIRECT_SPEC:0x7A','LDREX_SPEC:0x6C','speedup4l','speedup4b','speedup4b4l']
   #select_features=['L1D_CACHE_WB:0x15','DP_SPEC:0x73','L2D_CACHE_REFILL_ST:0x53','BR_MIS_PRED:0x10','BUS_CYCLES:0x1D','BR_INDIRECT_SPEC:0x7A','speedup4l','speedup4b','speedup4b4l'] #pmcs rodinia

   #wrapper method
   #select_features=['LDREX_SPEC:0x6C','UNALIGNED_LDST_SPEC:0x6A','L2D_CACHE_LD:0x50','L1D_CACHE_LD:0x40','L1D_CACHE_WB_CLEAN:0x47','ASE_SPEC:0x74','speedup4l','speedup4b','speedup4b4l'] #bots
   select_features=['L1D_CACHE_WB:0x15','L1D_CACHE_LD:0x40', 'L1D_CACHE_REFILL_LD:0x42', 'BR_PRED:0x12','DP_SPEC:0x73','BR_MIS_PRED:0x10','speedup4l','speedup4b','speedup4b4l'] #rodinia


elif core == 'biglittle':
   #filter method
   #select_features=['dcache_evic:0x15', 'data_rw_cache_access:0x04', 'no_cache_ext_mem_req:0xC1', 'bus_cycle:0x1D', 'L1D_CACHE_INVAL:0x48','L1D_CACHE_WB_CLEAN:0x47', 'L1D_CACHE_WB_VICTIM:0x46', 'UNALIGNED_ST_SPEC:0x69', 'EXC_TAKEN:0x09','LDREX_SPEC:0x6C','speedup4l','speedup4b','speedup4b4l']
   #select_features=['br_pred:0x10', 'inst_fetch_refill:0x01','read_alloc_mode:0xC5','data_rw_refill:0x03','ASE_SPEC:0x74','BUS_ACCESS:0x19','ST_SPEC:0x70','DP_SPEC:0x73','L1I_CACHE_ACCESS:0x14','BR_RETURN_SPEC:0x79','speedup4l','speedup4b','speedup4b4l'] #pmcs rodinia

   #wrapper method
   #select_features=['bus_cycle:0x1D','data_rw_refill:0x03','un_load_store:0x0F','l2d_cache_write:0x18', 'MEM_ACCESS_ST:0X67','L1D_CACHE_WB_CLEAN:0x47','L1D_CACHE_WB_VICTIM:0x46','L1D_CACHE_INVAL:0x48','UNALIGNED_ST_SPEC:0x69','BR_MIS_PRED:0x10','speedup4l','speedup4b','speedup4b4l'] #bots
   select_features=['data_rw_cache_access:0x04','reserved:0xC6', 'no_cache_ext_mem_req:0xC1','l2d_cache_refill:0x17','MEM_ACCESS:0x13','ASE_SPEC:0x74', 'MEM_ACCESS_ST:0x67','BUS_ACCESS_NORMAL:0x64','UNALIGNED_LDST_SPEC:0x6A','L1D_CACHE_REFILL:0x03','speedup4l','speedup4b','speedup4b4l'] #rodinia


else:
   print("Entrada invalida!!")


dataframe = pd.read_csv(fileName)
df = dataframe[select_features]

df_X = df.iloc[:, 0:len(df.columns)-3]
df_Y = df.iloc[:, len(df.columns)-3: len(df.columns)] 

X = df_X.values
Y = df_Y.values

models= [("DTR", DecisionTreeRegressor(max_depth=9)), #random_state=0,
         ('KNN', KNeighborsRegressor(n_neighbors=2)),
         ("RFR", RandomForestRegressor(n_estimators=550, n_jobs=-1)) #random_state=0,
         #("Neural_Network", MLPRegressor(hidden_layer_sizes=(500,300,150),alpha=0.01, batch_size=16,max_iter=10000, activation='relu', solver='adam', learning_rate='adaptive'))
        ]



def test_model(model_name):

   model = load(model_name)
   X = df.values
   print(len(X))
   for i in range(len(X)):
       result = model.predict([X[i]])
       print("Real:",Y[i] ,"Predict:",result[i])


for name, model in models:
   model = model
   model.fit(X, Y)
   Y_pred = model.predict(X)

   print(name, " R2:",r2_score(Y, Y_pred))
   output=name+"_"+core+".pkl"
   dump(model, output)
   #test_model(output)
   #print("\n\n")
