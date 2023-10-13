#!/bin/bash
#Gets all users of the sudo group

getent group sudo | cut -d ':' -f '4' | tr ',' ' ' > admins.txt
