#!/usr/bin/env python3
import sys
from random import randint
import joblib 
import numpy as np 

threshold=0.05

model_4l = joblib.load("/home/odroid/models/Decision_Tree_Regressor_little.pkl")
model_4b = joblib.load("/home/odroid/models/Decision_Tree_Regressor_big.pkl")
model_4b4l = joblib.load("/home/odroid/models/Decision_Tree_Regressor_biglittle.pkl")


actions = [3,7,23]

ref_arquivo = open("Output.txt","w", buffering=1)

def main():

    while True:
        l_p1,l_p2,l_p3,l_p4,l_p5,b_p1,b_p2,b_p3,b_p4,b_p5,b_p6,b_p7,state = input().split(',')

        l_p1 = float(l_p1)
        l_p2 = float(l_p2)
        l_p3 = float(l_p3)
        l_p4 = float(l_p4)
        l_p5 = float(l_p5)
        b_p1 = float(b_p1)
        b_p2 = float(b_p2)
        b_p3 = float(b_p3)
        b_p4 = float(b_p4)
        b_p5 = float(b_p5)
        b_p6 = float(b_p6)
        b_p7 = float(b_p7)

        state = int(state)

        if state == 3:
           sample = [[l_p2/l_p1,l_p3/l_p1,l_p4/l_p1,l_p5/l_p1]]

           out = model_4l.predict(sample).tolist()
           index_maior = np.argmax(out)

           out = out[0]

           n1=(index_maior+1)%3
           n2=(index_maior+2)%3

           if (abs(out[index_maior]-out[n1]) < threshold) or (abs(out[index_maior]-out[n2]) < threshold) :
                print(state)
           else:
                print(actions[np.argmax(out)])
                if state != actions[np.argmax(out)]:
                    ref_arquivo.write("Current State:4l "+"\n"+"Sample:"+ str(sample)+"\n"+ "Predictor:"+str(out)+" Config:"+str(actions[np.argmax(out)])+"\n")
                    ref_arquivo.write("\n")
        elif state == 7:
           sample = [[b_p2/b_p1,b_p3/b_p1,b_p4/b_p1,b_p5/b_p1,b_p6/b_p1,b_p7/b_p1]]
           out = model_4b.predict(sample).tolist()
           index_maior = np.argmax(out)

           out = out[0]

           n1=(index_maior+1)%3
           n2=(index_maior+2)%3


           if (abs(out[index_maior]-out[n1]) < threshold) or (abs(out[index_maior]-out[n2]) < threshold) :
                print(state)
           else:
                print(actions[np.argmax(out)])
                if state != actions[np.argmax(out)]: 
                    ref_arquivo.write("Current State:4b "+"\n"+"Sample:"+ str(sample)+"\n"+"Predictor:"+str(out)+" Config:"+str(actions[np.argmax(out)])+"\n")
                    ref_arquivo.write("\n")
        elif state == 23:
           sample = [[l_p2/l_p1,l_p3/l_p1,l_p4/l_p1,l_p5/l_p1,b_p2/b_p1,b_p3/b_p1,b_p4/b_p1,b_p5/b_p1,b_p6/b_p1,b_p7/b_p1]]
           out = model_4b4l.predict(sample).tolist()
           index_maior = np.argmax(out)

           out = out[0]

           n1=(index_maior+1)%3
           n2=(index_maior+2)%3

           if (abs(out[index_maior]-out[n1]) < threshold) or (abs(out[index_maior]-out[n2]) < threshold) :
                print(state)
           else:
                print(actions[np.argmax(out)])
                if state != actions[np.argmax(out)]:
                   ref_arquivo.write("Current State:4b4l "+"\n"+"Sample:"+ str(sample)+"\n"+ " Predictor:"+str(out)+" Config:"+str(actions[np.argmax(out)])+"\n")
                   ref_arquivo.write("\n")
        else:
           print(actions[randint(0, 2)])
           ref_arquivo.close();


if __name__ == "__main__":
    main()

