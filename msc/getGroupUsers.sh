#!/bin/bash
#Used to get all uses of a specified group
#Usage: './getGroupUsers.sh <group_name>'

if [ $# -ne 1 ]; then
	echo "Usage: $0 <group_name>"
	exit 1
fi

getent group $1 | cut -d ':' -f 4 | tr ',' ' ' > $1Users.txt
