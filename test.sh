#!/bin/bash -u
##############################################################
###############		        SETUP		      ################
##############################################################
# Set language to make sure same separator (, and .) config is being used
export LC_ALL=C.UTF-8
# Move to home directory
cd
# setup variables and arguments
while getopts ":f:n:a:t:" opt; do
  case $opt in
    n)
    DIR_NAME=$OPTARG
    ;;
    a)
    SAMPLES=$OPTARG
    ;;
    f)
    FILE_NAME=$OPTARG
    ;;
    t)
    TIME=$OPTARG
  esac
done
# check if arguments are given, if not set default values
# Name of the target directory
if [ -z "$DIR_NAME" ]
then
    DIR_NAME='default_DIR'
fi
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
# check if directory exists, if not then create it
if [ ! -d "$DIR_NAME" ]
then
    mkdir $DIR_NAME
fi
# List of events to monitor using perf
EVENTS=""
# Enter target directory
cd $DIR_NAME
# check if file exists, if not then create it
if [ ! -f "$DIR/$FILE_NAME.csv" ]
then
    # Create the file
    touch "$FILE_NAME.csv"
fi
##############################################################
#############		  OUTPUT FORMATTING  		##############
##############################################################
# Perf execution to get the order of the events (perf might not ouput them in the specified order)
perf stat -e "$EVENTS" --o "$TEMP_OUTPUT" -a sleep 1
placeholder=$(cat $TEMP_OUTPUT | cut -b 25- | cut -d " " -f 1 | tail -n +6 | head -n -3 | tr "\n" "," | sed 's/.$//')
# header line in file
echo "time;cpu_usage_pct;ram_usage_pct;network_in;network_out;${placeholder}" >> "$FILE_NAME.csv"
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
    network=$(echo `ifstat -i eth0 -q 1 1 | sed -n '3 p' | awk 'OFS=";" {print $1,$2}'`)
    hpc=$(cat "$TEMP_OUTPUT" | tr -s " " | cut -d " " -f 2 | tail -n 2 | head -n 1| tr "," ".")
    ##############################################################
	#############			   OUTPUT				##############
	##############################################################
    echo "$timestamp;$cpu;$mem;$network;$hpc" >> "$FILE_NAME.csv"
    #up counter and wait
    x=$(( $x + 1 ))
done
exit 0
