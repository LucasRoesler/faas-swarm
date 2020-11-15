#!/bin/sh

for i in {1..180};
do
    Ready="$(faas-cli describe echo | awk '{ if($1 ~ /Status:/) print $2 }')"
    if [[ $Ready == "Ready" ]];
    then
        exit 0
    fi
    sleep 1
done
