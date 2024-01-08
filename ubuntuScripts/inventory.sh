#!/bin/bash

# OS/Kernel
echo -e "[OS]"
echo -n "OS Version     : "
cat /etc/os-release | grep "PRETTY_NAME" | grep -o "\".*.\"" | tr -d '"'
echo -n "Kernel Version : "
uname -r
echo -n "Hostname       : "
hostname

# Admin Users
echo -e "\n[Admins]"
for g in adm sudo wheel; do getent group $g; done

# Users
echo -e "\n[Users]"
getent passwd | cut -d':' -f1,3,7 | grep -Ev "nologin|false"

# IP Address/MACs
echo -ne "\n[IP]\nRoute : "
ip -c route | grep "default"
echo -e ""
ip -br -c a
echo -e "\n[MAC]"
ip -br -c link

echo -e "\n[Ports]"
ss -tulpn | grep -v "127.0.0.*"
echo ""


##Hal Williams
#ima try and make this better based on our insperation, credit @d_tranman

#OS variable initialization
DEBIAN=false
REDHAT=false
ALPINE=false
SLACK=false
AMZ=false

#Debian distributions
UBUNTU=false
#MINT=false
#ELEMENTARY=false
#KALI=false
#RASPBIAN=false
#PROMOXVE=false
#ANTIX=false

#Red Hat Distributions
RHEL=false
#CENTOS=false
#FEDORA=false
#ORACLE=false
#ROCKY=false
#ALMA=false

#Alpine Distributions
#ADELIE=false
#WSL=false

#sets OS and distribution, distribution needs to be tested on a instance of each
DEBIAN{
    DEBIAN=true
    #Determine distribution
    if $(cat /etc/os-release | grep -qi Ubuntu) ; then
        UBUNTU=true
    #add more for each debian distro later
}
REDHAT{
    REDHAT=true
    #Determine distribution
    if [ -e /etc/redhat-release ] ; then
        RHEL=true
}
ALPINE{
    ALPINE=true
    #Determine distribution
}
SLACK{
    SLACK=true
    #Determine distribution
}
AMZ{
    AMZ=true
}

#Determines OS
if command -v apt-get >/dev/null ; then
    DEBIAN
elif command -v yum >/dev/null ; then
    REDHAT
elif command -v apk >/dev/null ; then
    ALPINE
elif command -v slapt-get >/dev/null || (cat /etc/os-release | grep -qi slackware ) ; then 
    SLACK
elif [ -e /etc/os-release ]; then
    source /etc/os-release
    if [ "$ID" = "amzn" ]; then
        AMZ
fi

#get hostname
HOST=$(hostname || cat /etc/hostname)
#get OS version
OS=$( cat /etc/*-release | grep PRETTY_NAME | sed 's/PRETTY_NAME=//' | sed 's/"//g' )
#get ipddress
IP=$( (ip a | grep -oE '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}/[[:digit:]]{1,2}' | grep -v '127.0.0.1') || { ifconfig | grep -oE 'inet.+([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}' | grep -v '127.0.0.1'; } )
#get users
USERS=$( cat /etc/passwd | grep -vE '(false|nologin|sync)$' | grep -E '/.*sh$' )
#get sudoers
SUDOERS=$(grep -h -vE '#|Defaults|^\s*$' /etc/sudoers /etc/sudoers.d/* | grep -vE '(Cmnd_Alias|\\)')
#get suid
SUID=$( find /bin /sbin /usr -perm)
