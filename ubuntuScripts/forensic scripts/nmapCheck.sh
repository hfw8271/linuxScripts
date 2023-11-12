#!/bin/bash
#Hal Williams
#checking open ports with nmap scans


main(){
    checks
    install
    nmap
    uninstall
}

checks(){
    #check that user is running as sudo
    if [[ $EUID -ne 0 ]]; then
        echo "User needs to be root. Not running script"
        exit 1
    fi

    #creating the directory for output
    sudo mkdir -p ./nmapFor

}

install(){
    #installing nmap quietly
    apt-get install -yqq nmap
}

nmap(){
    #scans all 65,535 ports
    nmap -A localhost > ./nmapFor/nmapAggressive.txt

    #scans for vulnarabilities
    nmap --script vuln localhost > ./nmapFor/nmapVuln.txt

    #checks ssh brute force
    nmap --script ssh-brute > ./nmapFor/nmapSSH.txt
}

uninstall(){

}

echo "nmap checker, all output will go to ./nmapFor"
main
echo "nmap checker has finished"