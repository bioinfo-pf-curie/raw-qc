#!/bin/bash

while getopts ":o:p:c:l:" optionName; do
case "$optionName" in
o) OUTPUTS_LIST="$OPTARG";;
p) OUTPUT_PATH="$OPTARG";;
c) CHECK_TIME="$OPTARG";;
l) LOG="$OPTARG";;
esac
done

echo "check RAW-QC analysis START" &>>$LOG
##CAN BE MODIFY##
##TIME LIMIT in seconds, currently equal to 24h
##CAN BE MODIFY##
time=0
while read file
do
    echo "FILE :" &>>$LOG
    echo $file &>>$LOG
    if [ ! -f $OUTPUT_PATH/$file ]
    then
        echo "The output file \'$OUTPUT_PATH/$file\' doesn't exist : check step is running" &>>$LOG
        while [[ $time -le $CHECK_TIME ]] ;
        do
            echo "The waiting time \'$time\' is checking" &>>$LOG
            if [ ! -f $OUTPUT_PATH/$file ] && [[ $time -le $CHECK_TIME ]]
            then
                echo "retest" &>>$LOG
                sleep 5s &&
                time=$((time+5))
            elif [ -f $OUTPUT_PATH/$file ]
            then
                echo "break" &>>$LOG
                break
            elif [[ $time -gt $CHECK_TIME ]]
            then
                echo "exit" &>>$LOG
                exit 1
            fi
        done
        if [ ! -f $OUTPUT_PATH/$file ] && ! [[ $time -le $CHECK_TIME ]]
        then
            echo "ERROR : The waiting time \'$time\' is greater than the time limit : $CHECK_TIME AND the file \'$OUTPUT_PATH/$file\' doesn't exist" &>>$LOG
            exit 1
        fi

    else
        echo "Waiting time : $time" &>>$LOG &&
        echo "File : $file is ok" &>>$LOG
    fi
    echo "Waiting time : $time" &>>$LOG &&
    echo "File : $file is ok" &>>$LOG
    echo "FILE END" &>>$LOG
done <$OUTPUTS_LIST
