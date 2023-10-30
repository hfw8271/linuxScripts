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
    if [[ $EUID -ne 0 ]]; then
        echo "User needs to be root. Not running script"
        exit 1
    fi
}

checkFilesPresent(){
    #dont add root to the users or admin files, you cant change root passowrd without other options enabled
    if [ ! -f "$USERS" ] then  
        echo "users.txt file not found, thus users cannot be properly configured"
        echo "please make a file called users.txt with all users that should be on the system, admin and regular users"
        exit 1
    if [ ! -f "$ADMINs" ] then
        echo "admins.txt file not found, thus admins cannot be properly configured"
        echo "please make a file called admins.txt with all admins that should be on the system"
        exit 1
}

### everything below saves logs, confgs, etc before the script makes changes
# use this crap for forensics
forensics(){
    getCurrentUsers()
    getBackupFiles()
    getServicesRuning()
    getBashHistory()
    getCrontab()
    getPasswdGroup()
    getHost()
}

getCurrentUsers(){
    while IFS=: read -r username password uid gid gecos home shell; do
	echo "$username" >> ./forensics/allUsers.txt
    done < "/etc/passwd"
}

getBackupFiles(){
    cp -r /var/log ./forensics/backups/varLogBackups
    cp -r /etc/apt ./forensics/backups/aptBackups
    cp /etc/apt/apt.conf.d/10periodic ./forensics/backups/10periodic
    cp /etc/apt/apt.conf.d/20auto-upgrades ./forensics/backups/20auto-upgrades
    cp /ect/apt/sources.list ./forensics/backups/sources.list
}

getServicesRuning(){
    netstat -tuln > ./forensics/services/services.txt
    ps auxf > ./forensics/services/ps.txt
}

getBashHistory(){
    last >  ./forensics/bashHistory/last.txt
    for user in $(cat ./forensics/allUsers.txt); do
        cat /home/$user/.bash_history > ./forensics/bashHistory/"$user"_bashHistory.txt
    done;
}

getCrontab(){
    for user in $(cat ./forensics/allUsers.txt); do
        crontab -u $user -l > ./forensics/"$user"_crontab.txt
    done;
    cp -r /etc/cron.daily ./forensics/cron/cron_daily
    cp -r /etc/cron.hourly ./forensics/cron/cron_hourly
    cp -r /etc/cron.weekly ./forensics/cron/cron_weekly
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

}

setPackages(){
    apt-get update > /dev/null
    apt-fast install -y debsum
    apt-fast install -y net-tools
    apt-fast install -y apt
    apt-fast update -y
    apt-fast install --reinstall $(dkpg -S $(debsums -c) | cut -d : -f 1 | sort -u) -y
    
}