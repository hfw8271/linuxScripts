#!/bin/bash

# List of expected users
expected_users=(
    "root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy"
    "www-data" "backup" "list" "irc" "gnats" "nobody" "systemd" "syslog" "messagebus"
    "_apt" "lxd" "uuidd" "avahi" "ntp" "sshd" "mysql" "pulse" "rtkit" "snmp" "colord"
    "usbmux" "dnsmasq" "vboxadd" "sddm" "lightdm" "gdm" "kernoops" "pulse-access"
    "sambashare" "docker"
)

# Output files
expected_users_file="expected_users.txt"
unexpected_users_file="unexpected_users.txt"

# Create expected users file and write header
echo -e "Expected Users:\tRoot Directory:\tLogin Allowed:" > "$expected_users_file"

# Create unexpected users file and write header
echo -e "Unexpected Users:\tRoot Directory:\tLogin Allowed:" > "$unexpected_users_file"

# Initialize arrays to store found users, their home directories, and login allowed status
e_users=""
ue_users=""

# Iterate through /etc/passwd and check if each user exists in expected_users
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

echo "Expected users with root directories and login status have been saved to $expected_users_file"
echo "Unexpected users with root directories and login status have been saved to $unexpected_users_file"

