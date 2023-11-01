# Hal Williams
# credits to Justin Huang for a lot of the code
# I made a lot of changes, trying to make it self explanitory and adding comments.
# also added a lot of stuff

#things to look at before running:
#probably smart to have a root terminal open, 
#   incase your users sudo access is broken you can fix it manually
#

echo "bruh lets win"


chandiFortnite(){
    starterChecks()
    forensics()
}

### makes sure that you are the root and have the users and admins files

starterChecks(){
    areYouSudo()
    neededFilesPresent()
}

checkSudo(){
    #gotta be sudo to run this, duh
    if [[ $EUID -ne 0 ]]; then
        echo "User needs to be root. Not running script"
        exit 1
    fi
}

checkFilesPresent(){
    USERS=./users.txt
    ADMINS=./admins.txt

    #dont add root to the users or admin files, you cant change root passowrd without other options enabled
    if [ ! -f "$USERS" ] then  
        echo "users.txt file not found, thus users cannot be properly configured"
        echo "please make a file called users.txt with all users that should be on the system, admin and regular users"
        #you dont need deamons or root here, just users, root wont matter because everything for root is already configured in the script
        exit 1
    if [ ! -f "$ADMINS" ] then
        echo "admins.txt file not found, thus admins cannot be properly configured"
        echo "please make a file called admins.txt with all admins that should be on the system"
        exit 1
}

makeDir(){
    sudo mkdir -p ./forensics
    sudo mkdir -p ./forensics/backups
    sudo mkdir -p ./forensics/running
    sudo mkdir -p ./forensics/bashHistory
    sudo mkdir -p ./forensics/cron
}

### everything below saves logs, confgs, etc before the script makes changes
# use this crap for forensics
forensics(){
    getUsers()
    getBackupFiles()
    getRuning()
    getBashHistory()
    getCron()
    getPasswdGroup()
    getHost()
}

#outputs a file to ./forensics/allUsers.txt to see what users were on the system.
#gets all users login and logout history to ./forensics/logins.txt
getUsers(){
    while IFS=: read -r username password uid gid gecos home shell; do
	echo "$username" >> ./forensics/allUsers.txt
    done < "/etc/passwd"

    last >  ./forensics/logins.txt
}

#outputs backup files of logs and conf files that are changed to ./forensics/backups
getBackupFiles(){
    sudo cp -r /var/log ./forensics/backups/varLogBackups
    sudo cp -r /etc/apt ./forensics/backups/aptBackups
    sudo cp /etc/apt/apt.conf.d/10periodic ./forensics/backups/10periodic
    sudo cp /etc/apt/apt.conf.d/20auto-upgrades ./forensics/backups/20auto-upgrades
    sudo cp /etc/apt/sources.list ./forensics/backups/sources.list
}

#outputs the services and processes running to ./forensics/services
getRuning(){
    sudo netstat -tuln > ./forensics/running/services.txt
    sudo ps auxf > ./forensics/running/processes.txt
}

#outputs bash history for all users to ./forensics/bashHistory/$user_bashHistory.txt 
getBashHistory(){
    while IFS= read -r user; do
        if [ -f "/home/$user/.bash_history" ]; then
            cp "/home/$user/.bash_history" "./forensics/bashHistory/${user}_bashHistory.txt"
        fi
    done < "./forensics/allUsers.txt"
}

#gets the crontab of all users and outputs it to ./forensics/cron/$user_crontab.txt
#outputs copies of cron daily, hourly, and weekly to ./forensics/cron
getCron(){
    while IFS= read -r user; do
            crontab -u "$user" -l > "./forensics/cron/${user}_crontab.txt"
    done < "./forensics/allUsers.txt"

    cp -r /etc/cron.daily ./forensics/cron/cron.daily
    cp -r /etc/cron.hourly ./forensics/cron/cron.hourly
    cp -r /etc/cron.weekly ./forensics/cron/cron.weekly
}

getPasswdGroup(){
    cat /etc/passwd ./forensics/pass_group/passwd
    cat /etc/group ./forensics/pass_group/group
}

getHosts() {
    cp /etc/hosts.deny ./forensics/hosts/host.deny
    cp /etc/hosts.allow ./forensics/hosts/hosts.allow
    cp /etc/hosts.conf ./forensics/hosts/host.conf
}

### everything below makes changes
fixes(){
    setAliases()
    setAutoUpdatesAutoUpgrades()
    setApt()
    setPackages()
    setChattr()
    setNetwork()
}

setAliases(){
    for user in $(cat users.txt); do
        cat configs/bashrc > /home/$user/.bashrc;
    done;
    cat configs/bashrc > /root/.bashrc
    cat configs/profile > /etc/profile
}

setAutoUpdatesAutoUpgrades(){
    cat configs/10periodic > /etc/apt/apt.conf.d/10periodic
    cat configs/20auto-upgrades > /etc/apt/apt.conf.d/20auto-upgrades
}

setApt(){
    #set apt sources list
    cat configs/sources.list > /etc/apt/sources.list
    #installing apt-fast
    sudo add-apt-repository ppa:apt-fast/stable
    sudo apt update -y
    sudo apt install curl -y
    sudo apt install realpath -y
    sudo apt update -y
    /bin/bash -c "$(curl -sL https//git.io/vokNn)"
    sudo sed -i '/_MAXCONPERSRV/c\_MAXCONPERSRV=20' /etc/apt-fast.conf
}

setPackages(){
    apt-get update > /dev/null
    apt-get install -y debsum
    apt-get install -y net-tools
    apt-get install -y apt
    apt-get update -y
    apt-get install --reinstall $(dkpg -S $(debsums -c) | cut -d : -f 1 | sort -u) -y
    apt-get install --reinstall ufw libpan-pwquality procps net-tools findutils binutils coreutils -y
    xargs -rd '\n' -a <(sudo debsums -c 2>&1 | cut -d " " -f 4 | sort -u | xargs -rd '\n' -- dkpg -S | cut -d : -f 1 | sort -u) -- sudo apt-get install -f --reinstall --
    apt-get install -y ufw
    apt-get install -y libpam-pwquality
    apt-get install -y libpam-faillock
    apt-get install -y sudo
    apt-get install -y firefox
}

setChattr(){
    chattr -ia /etc/passwd
    chattr -ia /etc/group
    chattr -ia /etc/shadow
    chattr -ai /etc/passwd-
    chattr -ia /etc/group-
    chattr -ia /etc/shadow-
}

setNetwork(){
    service network-manager restart
    host_rules()
    firewall()
}

setHost(){
    #Set hosts manually before running the script
    #echo "ALL:ALL" > /etc/hosts.deny
    #echo "#PUT THE SERVICES YOU WANT#" > /etc/hosts.allow
    #echo "" > /etc/host.conf
}

setFirewall(){
    #modify the set up for ufw as needed
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22
    #add other rules here
    sudo ufw enable

}

setUsers(){
    cat configs/adduser.conf > /etc/adduser.conf
    cat configs/deluser.conf > /etc/deluser.conf

    for user in $(cat users.txt); do

}

setPerms(){
    ./perms.sh
}

chandiFortnite()