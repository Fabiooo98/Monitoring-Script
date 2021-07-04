#!/bin/bash -u
##############################################################
###############		        SETUP		      ################
##############################################################
# Set language to make sure same separator (, and .) config is being used
export LC_ALL=C.UTF-8

# setup variables and arguments
while getopts ":f:a:t:h" opt; do
  case $opt in
    a)
    SAMPLES=$OPTARG
    ;;
    f)
    FILE_NAME=$OPTARG
    ;;
    t)
    TIME=$OPTARG
    ;;
    h)
    echo "Usage:"
    echo "This script is used to monitor the internal behaviour of a Raspberry Pi."
    echo ""
    echo "The following arguments can be given: -a | -f | -t"
    echo ""
    echo "Options:"
    echo "-a        To set the amounf of samples to be taken. Default is 10 samples."
    echo "-f        To name the output file. Default is 'data'."
    echo "-t        To set the time between samples (in seconds). Default is 10 seconds."
    exit 0
  esac
done
# check if arguments are given, if not set default values
# Amount of samples to be taken
if [ -z "$SAMPLES" ]
then
    SAMPLES=10
fi
# Name of the target file
if [ -z "$FILE_NAME" ]
then
    FILE_NAME='data'
fi
# Time between samples
if [ -z "$TIME" ]
then
    TIME=10
fi
# List of events to monitor using perf
EVENTS=""
# check if file exists, if not then create it
if [ ! -f "$FILE_NAME.csv" ]
then
    # Create the file
    touch "$FILE_NAME.csv"
fi
FINAL_OUTPUT="$FILE_NAME.csv"
TEMP_OUTPUT=temp
##############################################################
#############		  OUTPUT FORMATTING  		##############
##############################################################
# Perf execution to get the order of the events (perf might not ouput them in the specified order)
perf stat -e "$EVENTS" --o "$TEMP_OUTPUT" -a sleep 1
placeholder=$(cat $TEMP_OUTPUT | cut -b 25- | cut -d " " -f 1 | tail -n +6 | head -n -3 | tr "\n" "," | sed 's/.$//')
# header line in file
echo "time,cpu_usage_pct,ram_usage_pct,network_in,network_out,${placeholder}" >> $FINAL_OUTPUT
##############################################################
#############		   MONITORING LOOP			##############
##############################################################
x=1
while [ $x -le $SAMPLES ]
do
    ##############################################################
	#############		   DATA COLLECTION			##############
	##############################################################
    # Perf data collection
    perf stat -e "$EVENTS" --o "$TEMP_OUTPUT" -a sleep "$TIME"
    # Data extraction
    timestamp=$(echo `date +'%T'`)
    cpu=$(echo `top -b -n1 | grep "Cpu(s)" | awk '{print $2 + $4}'`)
    mem=$(echo `free | grep Mem | awk '{print $3/$2}'`)
    network=$(echo `ifstat -i eth0 -q 1 1 | sed -n '3 p' | awk 'OFS="," {print $1,$2}'`)
    hpc=$(cat "$TEMP_OUTPUT" | cut -c -20 | tr -s " " | tail -n +6 | head -n -3 | tr "\n" "," | sed 's/ //g'| sed 's/.$//')
    ##############################################################
	#############			   OUTPUT				##############
	##############################################################
    echo "$timestamp,$cpu,$mem,$network,$hpc" >> $FINAL_OUTPUT
    #up counter and wait
    x=$(( $x + 1 ))
done
exit 0
