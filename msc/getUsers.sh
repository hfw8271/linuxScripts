#!/bin/bash

rm users.txt

touch users.txt

while IFS=: read -r username password uid gid gecos home shell; do
	echo "$username" >> users.txt
done < "/etc/passwd"

