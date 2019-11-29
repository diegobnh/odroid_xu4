#!/usr/bin/env python3
import sys
from random import randint
import joblib
import numpy as np

threshold=0.05


file_name="/home/odroid/models/performancelittle.pkl"
performance_model_4l = joblib.load(file_name)
file_name="/home/odroid/models/performancebig.pkl"
performance_model_4b = joblib.load(file_name)
file_name="/home/odroid/models/performancebiglittle.pkl"
performance_model_4b4l = joblib.load(file_name)

file_name="/home/odroid/models/powerlittle.pkl"
power_model_4l = joblib.load(file_name)
file_name="/home/odroid/models/powerbig.pkl"
power_model_4b = joblib.load(file_name)
file_name="/home/odroid/models/powerbiglittle.pkl"
power_model_4b4l = joblib.load(file_name)


apps = ['fib','nqueens','health','floorplan','fft','sort','sparselu','strassen','backprop','heartwall','lavaMD','particle_filter']
actions = [3,7,23]
actions_name=["4l","4b","4b4l"]

file_name="stdout_predictor"
ref_arquivo = open(file_name,"a", buffering=1)


def main():
    app_count=0
    flag = True

    ref_arquivo.write(apps[0]+"\n")
    while flag:
        try:
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
                sample = [[l_p1,l_p2,l_p3,l_p4,l_p5]]
                performance_out = performance_model_4l.predict(sample).tolist()
                power_out = power_model_4l.predict(sample).tolist()
                edp = (np.ones(len(performance_out))*performance_out*power_out).tolist()

            elif state == 7:
                sample = [[b_p1,b_p2,b_p3,b_p4,b_p5,b_p6,b_p7]]
                performance_out = performance_model_4b.predict(sample).tolist()
                power_out = power_model_4b.predict(sample).tolist()
                edp = (np.ones(len(performance_out))*performance_out*power_out).tolist()

            elif state == 23:
                sample = [[l_p1,l_p2,l_p3,l_p4,l_p5,b_p1,b_p2,b_p3,b_p4,b_p5,b_p6,b_p7]]
                performance_out = performance_model_4b4l.predict(sample).tolist()
                power_out = power_model_4b4l.predict(sample).tolist()
                edp = (np.ones(len(performance_out))*performance_out*power_out).tolist()

            elif state == -1:
                app_count = app_count+1
                index = app_count % 12
                ref_arquivo.write("\n")
                ref_arquivo.write(apps[index]+"\n")

            else:
                ref_arquivo.write("state invalid:" + str(state))
                break;

            ref_arquivo.write("\""+str(actions_name[np.argmax(performance_out)])+"\""+",")
            #ref_arquivo.write("\"" + str(performance_out[0]) + " " + str(power_out[0]) + " " + str(out[0]) + " " + str(actions[np.argmax(performance_out)]) + " " + str(actions[np.argmin(power_out)]) + " " + str(actions[np.argmin(out)]) + "\"" + "\n")
            print(actions[np.argmax(performance_out)])

        except EOFError:
            #ref_arquivo.write("\n EOFError \n")
            flag = False

if __name__ == "__main__":
    main()
