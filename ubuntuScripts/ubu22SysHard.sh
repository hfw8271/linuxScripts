#!/bin/bash

#must be root to run
if [[ $EUID -ne 0 ]]; then
        echo "User needs to be root. Not running script"
        exit 1
    fi

#Package integrity
for i in $(dpkg -l | awk '{print $2}'); do 
    result=$(dpkg --verify $i | grep -E "^[^c]")
    if [[ $result == *"missing"* ]]; then
        echo $i >> missing_packages.txt
done

#