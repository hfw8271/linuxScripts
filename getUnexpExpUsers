#!/bin/bash
#Iterates through a list of 'expected' users on a linux system
#and compares them to each user in /etc/passwd 
#outputs two files with expected users and unexpected users
#includes the home directory and the shell of each


expected_users=(
    "root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy"
    "www-data" "backup" "list" "irc" "gnats" "nobody" "systemd" "syslog" "messagebus"
    "_apt" "lxd" "uuidd" "avahi" "ntp" "sshd" "mysql" "pulse" "rtkit" "snmp" "colord"
    "usbmux" "dnsmasq" "vboxadd" "sddm" "lightdm" "gdm" "kernoops" "pulse-access"
)

expected_users_file="expected_users.txt"
unexpected_users_file="unexpected_users.txt"

echo -e "Expected Users:\tRoot Directory:\tLogin Allowed:" > "$expected_users_file"
echo -e "Unexpected Users:\tRoot Directory:\tLogin Allowed:" > "$unexpected_users_file"

e_users=""
ue_users=""

while IFS=: read -r username password uid gid gecos home shell; do
    if [[ " ${expected_users[@]} " =~ " $username " ]]; then
        e_users+="$username"
        e_users+="\t$home"
        e_users+="\t$shell\n"
    else
        ue_users+="$username"
        ue_users+="\t$home"
        ue_users+="\t$shell\n"
    fi
done < "/etc/passwd"

echo -e "$e_users" >> "$expected_users_file"
echo -e "$ue_users" >> "$unexpected_users_file" 
