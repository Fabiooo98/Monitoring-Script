#!/bin/bash -u

# Set language to make sure same separator (, and .) config is being used
export LC_ALL=C.UTF-8

# Move to home directory
cd
# setup variables and arguments
# Name of the directory
DIR_NAME=$1
# Name of the file
FILE_NAME="data"
# Time window per sample
timeWindow=10
# Number of sampoles to be taken
samples=1000

# check if arguments are given
if [[ -z "$DIR_NAME" || -z "$FILE_NAME" ]]
then
    echo "Missing Arguments"
    exit -1
fi
# check if directory exists, if not then create it
if [ ! -d "$DIR_NAME" ]
then
    mkdir $DIR_NAME
fi
# Enter target directory
cd $DIR_NAME
# check if file exists, if not then create it
if [ ! -f "$DIR/$FILE_NAME.csv" ]
then
    # Create the file
    touch "$FILE_NAME.csv"
fi
# header line in file
echo 'time,cpu_usage_pct,ram_usage_pct,network_in,network_out' >> "$FILE_NAME.csv"
# insert monitoring dimensions in file for 10 seoncds
x=1
while [ $x -le $samples ]
do
    printf `date +'%T'";"` >> "$FILE_NAME.csv"
    printf `top -b -n1 | grep "Cpu(s)" | awk '{print $2 + $4}'`";" >> "$FILE_NAME.csv"
    printf `free | grep Mem | awk '{print $3/$2}'`";" >> "$FILE_NAME.csv"
    printf `ifstat -i eth0 -q 1 1 | sed -n '3 p' | awk 'OFS=";" {print $1,$2}'` >> "$FILE_NAME.csv"
    printf "\n" >> "$FILE_NAME.csv"
    #up counter and wait 5 seconds
    x=$(( $x + 1 ))
    sleep $timeWindow
done
pwd
exit 0
