#!/bin/bash


#esses comandos abaixo devem ser rodados no terminal e n  o dentro desse script
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 1.tar std* *.energy; sleep 5; sudo rm std* *.energy;
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 2.tar std* *.energy; sleep 5; sudo rm std* *.energy;
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 3.tar std* *.energy; sleep 5; sudo rm std* *.energy;
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 4.tar std* *.energy; sleep 5; sudo rm std* *.energy;
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 5.tar std* *.energy; sleep 5; sudo rm std* *.energy;
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 6.tar std* *.energy; sleep 5; sudo rm std* *.energy;
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 7.tar std* *.energy; sleep 5; sudo rm std* *.energy;
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 8.tar std* *.energy; sleep 5; sudo rm std* *.energy;
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 9.tar std* *.energy; sleep 5; sudo rm std* *.energy;
sudo taskset -a -c 0-7 ./bin/scheduler > /dev/null 2> stderror_schedule; sudo tar -cf 10.tar std* *.energy; sleep 5; sudo rm std* *.energy;


