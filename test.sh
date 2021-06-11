cd
# setup variables and arguments
DIR_NAME=$1
FILE_NAME=$2
DIR="/home/fabio/$DIR_NAME"
# check if arguments are given
if [[ -z "$DIR_NAME" || -z "$FILE_NAME" ]]
then
    echo "Missing Arguments"
    exit -1
fi
# check if directory exists, if not then create it
if [ ! -d "$DIR" ]
then
    mkdir $DIR_NAME
fi
cd $DIR_NAME
# check if file exists, if not then create it
if [ ! -f "$DIR/$FILE_NAME.txt" ]
then
    touch "$FILE_NAME.txt"
fi
exit 0
