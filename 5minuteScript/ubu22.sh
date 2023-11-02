#!/bin/bash
# Hal Williams
# credits to Justin Huang for a lot of the code
# I made a lot of changes, trying to make it self explanitory and adding comments.
# also added a lot of stuff

#things to look at before running:
#probably smart to have a root terminal open, 
#   incase your users sudo access is broken you can fix it manually
#

echo "bruh lets win"

USERS=./users.txt
ADMINS=./admins.txt

chandiFortnite(){
    starterChecks
    forensics
    fixes
}

### makes sure that you are the root and have the users and admins files

starterChecks(){
    echo "check sudo"
    checkSudo
    echo "check files"
    checkFilesPresent
    echo "mk dir"
    makeDir
}

checkSudo(){
    #gotta be sudo to run this, duh
    if [[ $EUID -ne 0 ]]; then
        echo "User needs to be root. Not running script"
        exit 1
    fi
}

checkFilesPresent(){

    #dont add root to the users or admin files, you cant change root passowrd without other options enabled
    if [ ! -f "$USERS" ]; then  
        echo "users.txt file not found, thus users cannot be properly configured"
        echo "please make a file called users.txt with all users that should be on the system, admin and regular users"
        #you dont need deamons or root here, just users, root wont matter because everything for root is already configured in the script
        exit 1
    fi
    if [ ! -f "$ADMINS" ]; then
        echo "admins.txt file not found, thus admins cannot be properly configured"
        echo "please make a file called admins.txt with all admins that should be on the system"
        exit 1
    fi
}

#######sill gotta make some 
makeDir(){
    sudo mkdir -p ./forensics
    sudo mkdir -p ./forensics/backups
    sudo mkdir -p ./forensics/running
    sudo mkdir -p ./forensics/bashHistory
    sudo mkdir -p ./forensics/cron
    sudo mkdir -p ./postrun
}

### everything below saves logs, confgs, etc before the script makes changes
# use this crap for forensics
forensics(){
    echo "get users"
    getUsers
    echo "get backups"
    getBackupFiles
    echo "get running"
    getRuning
    echo "get bash history"
    getBashHistory
    echo "get cron"
    getCron
    echo "get passwd group"
    getPasswdGroup
    echo "get"
    getHost
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
    echo "setAliases"
    setAliases
    echo "set updates and upgrades"
    setAutoUpdatesAutoUpgrades
    echo "set apt"
    setApt
    echo "set packages"
    setPackages
    echo "set chattr"
    setChattr
    echo "set network"
    setNetwork
    echo "set users"
    setUsers
    echo "set perms"
    setPerms
    echo "set passwords"
    setPasswords
    echo "set lock"
    setLock
    echo "set rhost"
    setRhost
    echo "set host equiv"
    setHostEquiv
    echo "set sudo"
    setSudo
    echo "set guest"
    setGuest
    echo "set pass policy"
    setPassPolicy
    echo "set dconf"
    setDconf
    echo "set no malware"
    setNoMalware
    echo "set no media files"
    setNoMediaFiles
    echo "rando time"
    random
    echo "last check"
    lastChecks
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
    #host
    firewall
}

host(){
    echo ""
    #Set hosts manually before running the script
    #echo "ALL:ALL" > /etc/hosts.deny
    #echo "#PUT THE SERVICES YOU WANT#" > /etc/hosts.allow
    #echo "" > /etc/host.conf
}

firewall(){
    #modify the set up for ufw as needed
    sudo ufw --force reset
    sudo ufw enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw logging high
    sudo ufw allow 22
    #add other rules here
    sudo ufw enable

}

setUsers(){
    copyConfigFiles
    manageUsers
    manageUserGroups
}

copyConfigFiles() {
    cat configs/adduser.conf > /etc/adduser.conf
    cat configs/deluser.conf > /etc/deluser.conf
}

# Function to add or remove users based on a user list
manageUsers() {
    local user_list="users.txt"

    # Add or update users
    while read -r user; do
        if ! grep -q "$user" /etc/passwd; then
            useradd -m -s /bin/bash "$user"
        fi
        crontab -u "$user" -r
    done < "$user_list"

    # Remove users not in the user list
    while read -r user; do
        if ! grep -q "$user" "$user_list"; then
            deluser "$user" 2> /dev/null
        fi
    done < <(cut -d: -f1 /etc/passwd | grep -e "[5-9][0-9][0-9]" -e "[0-9][0-9][0-9][0-9]" | grep "/home")
}

manageUserGroups() {
    local user_list="users.txt"
    local admin_list="admins.txt"

    while IFS=: read -r username uid home; do
        local BadUser=0

        if grep -qi "$username" "$user_list"; then
            if grep -q "$username" /etc/group | grep -q "sudo"; then
                deluser "$username" sudo
            fi

            if grep -q "$username" /etc/group | grep -q "adm"; then
                deluser "$username" adm
            fi
        else
            BadUser=$((BadUser+1))
        fi

        if grep -qi "$username" "$admin_list"; then
            if ! grep -q "$username" /etc/group | grep -q "sudo"; then
                usermod -a -G "sudo" "$username"
            fi

            if ! grep -q "$username" /etc/group | grep -q "adm"; then
                usermod -a -G "adm" "$username"
            fi
        else
            BadUser=$((BadUser+1))
        fi

        if [ "$BadUser" -eq 2 ]; then
            echo "WARNING: USER $username HAS AN ID THAT IS CONSISTENT WITH A NEWLY ADDED USER YET IS NOT MENTIONED IN EITHER THE admins.txt OR users.txt FILE. LOOK INTO THIS."
        fi
    done < <(cut -d: -f1,3,6 /etc/passwd | grep -e "[5-9][0-9][0-9]" -e "[0-9][0-9][0-9][0-9]" | grep "/home")
}

setPerms(){
    df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t
	bash ./perms.sh
}

setPasswords(){
    echo 'root:G59vCHe0T8fcdQ1' | chpasswd;
    passwd -l root;

    while IFS=: read -r user; do
        passwd -q -x 85 "$user" > /dev/null
        passwd -q -n 15 "$user" > /dev/null

        echo "$user:G59vCHe0T8fcdQ1" | chpasswd
        change --maxdays 15 -mindays 6 -warndays 7 --inactive 5 "$user"

    done < "./users.txt"
}

setLock(){
    users=($(cat users.txt admins.txt))

    while IFS=: read user _; do
        if [[ ! "${users_to_keep[@]} " =~ " $user " ]]; then 
            echo "Locking user: $user" 
            passwd -l "$user"
        fi
    done < /etc/passwd
}       

setRhost(){
    echo "deleting rhosts"
    find / -name ".rhost" -exec rm -rf {} \;
}

setHostEquiv(){
    echo "deleting host.equiv"
    find / -name "host.equiv" -exec rm -rf {} \;
}

setSudo(){
    echo "resetting sudoers and README"
    cat configs/sudoers > /etc/sudoers
    cat configs/README > /etc/sudoers.d/README
    #idk why just trust
    rm -f /etc.sudoers.d/*
}

setGuest(){
    echo "bye bye guest accounts"
    cat configs/custon.conf > /etc/gdm3/custon.conf
}

setPassPolicy(){
    echo "password policy"
    cat configs/login.defs > /etc/login.defs
	cat configs/common-password > /etc/pam.d/common-password
	cat configs/common-auth > /etc/pam.d/common-auth
	cat configs/pwquality.conf > /etc/security/pwquality.conf
}

setDconf(){
    dconf reset -f /
	gsettings set org.gnome.desktop.privacy remember-recent-files false
	gsettings set org.gnome.desktop.media-handling automount false
	gsettings set org.gnome.desktop.media-handling automount-open false
	gsettings set org.gnome.desktop.search-providers disable-external true
	dconf update /
}

setNoMalware(){
    touch ./postrun/malware
    echo "checking for and deleting malware"
     apt-get purge -y john*
     apt-get purge -y netcat*
     apt-get purge -y telnet*
     apt-get purge -y iodine*
     apt-get purge -y kismet*
     apt-get purge -y medusa*
     apt-get purge -y hydra*
     apt-get purge -y rsh-server*
     apt-get purge -y fcrackzip*
     apt-get purge -y ayttm*
     apt-get purge -y empathy*
     apt-get purge -y nikto*
     apt-get purge -y logkeys*
     apt-get purge -y nfs-kernel-server*
     apt-get purge -y vino*
     apt-get purge -y tightvncserver*
     apt-get purge -y rdesktop*
     apt-get purge -y remmina*
     apt-get purge -y vinagre*
     apt-get purge -y ettercap*
     apt-get purge -y knocker*
	 apt-get purge -y openarena*
     apt-get purge -y openarena-server*
     apt-get purge -y wireshark*
     apt-get purge -y minetest*
     apt-get purge -y minetest-server*
     apt-get purge -y ophcrack*
     apt-get purge -y aircrack-ng*
	 apt-get purge -y crack*
	 apt-get purge -y aircrack*
	 apt-get purge -y freeciv*
	 apt-get purge -y p0f
	 apt-get purge -y nbtscan*
	 apt-get purge -y endless-sky*
	 apt-get purge -y netdiag*
     apt-get purge -y hunt
     apt-get purge -y dsniff
	 apt-get purge -y irc*
	 apt-get purge -y cl-irc*
	 apt-get purge -y snmp*
	 apt-get purge -y snmpd*
	 apt-get purge -y rsync*
	 apt-get purge -y postfix*
	 apt-get purge -y ldp*
	 apt purge john* -y
	 apt purge nmap* -y
	 apt purge wireshark* -y
	 apt purge metasploit* -y
	 apt purge wesnoth* -y
	 apt purge kismet* -y
	 apt purge freeciv* -y
	 apt purge zenmap* -y
	 apt purge zenmap nmap* -y
	 apt purge Minetest* -y
	 apt purge minetest* -y
	 apt purge knocker* -y
	 apt purge bittorrent* -y
	 apt purge torrent* -y
	 apt purge torrent* -y
	 apt purge p0f -y
	 apt purge tightvnc* -y
	 apt purge postgresql* -y
	 apt purge postgres* -y
	 apt purge ophcrack* -y
	# apt purge crack* -y
	 apt purge aircrack* -y
	 apt purge aircrack-ng -y
	 apt purge ettercap* -y
	sudo apt purge irc* -y
	sudo apt purge cl-irc* -y
	sudo apt purge openarena* -y
	sudo apt purge rsync* -y
	sudo apt purge hydra* -y
	sudo apt purge medusa* -y
	sudo apt purge armagetron* -y
	sudo apt purge nikto* -y
	sudo apt purge postfix* -y
	sudo apt purge nbtscan* -y
	sudo apt purge cyphesis* -y
	sudo apt purge endless-sky* -y
	sudo apt purge hunt -y
	sudo apt purge snmp* -y
	sudo apt purge snmpd -y
	sudo apt purge dsniff* -y
	sudo apt purge lpd -y
	sudo apt purge vino* -y
	sudo apt purge netris* -y
	sudo apt purge bestat* -y
	sudo apt purge remmina -y
	sudo apt purge netdiag -y
	sudo apt purge inspircd* -y
	sudo apt purge up.time -y
	sudo apt purge uptimeagent -y
	sudo apt purge chntpw* -y
	#sudo apt purge perl -y
	sudo apt purge nfs* -y
	sudo apt purge nfs-kernel-server* -y
	#sudo apt purge ldap* -y
	sudo apt purge abc -y
	sudo apt purge sqlmap -y
	sudo apt purge acquisition -y
	sudo apt purge bitcomet* -y
	sudo apt purge bitlet* -y
	sudo apt purge bitspirit* -y
	sudo apt purge minetest-server* -y
	sudo apt purge armitage -y
	sudo apt purge airbase-ng* -y
	sudo apt purge qbittorrent* -y
	sudo apt purge ctorrent* -y
	sudo apt purge ktorrent* -y
	sudo apt purge rtorrent* -y
	sudo apt purge deluge* -y
	sudo apt purge tixati* -y
	sudo apt purge frostwise -y
	sudo apt purge vuse -y
	sudo apt purge irssi -y
	sudo apt purge transmission-gtk -y
	sudo apt purge utorrent* -y
	sudo apt purge exim4* -y
	sudo apt purge telnetd -y
	sudo apt purge crunch -y
	sudo apt purge tcpdump -y
	sudo apt purge tomcat -y
	sudo apt purge tomcat6 -y
	sudo apt purge vncserver* -y
	sudo apt purge tightvnc* -y
	sudo apt purge tightvnc-common* -y
	sudo apt purge tightvncserver* -y
	sudo apt purge vnc4server* -y
	sudo apt purge nmdb -y
	sudo apt purge dhclient -y
	sudo apt purge telnet-server -y
	sudo apt purge cryptcat* -y
	sudo apt purge snort -y
	sudo apt purge pryit -y
	sudo apt purge gameconqueror* -y
	sudo apt purge weplab -y
	sudo apt purge lcrack -y
	sudo apt purge dovecot* -y
	sudo apt purge pop3 -y
	sudo apt purge ember -y
	sudo apt purge manaplus* -y
	sudo apt purge xprobe* -y
	sudo apt purge openra* -y
	sudo apt purge ipscan* -y
	sudo apt-get remove python-scapy -y
	sudo apt purge arp-scan* -y
	sudo apt purge squid* -y
	sudo apt purge heartbleeder* -y
	sudo apt purge linuxdcpp* -y
	sudo apt purge cmospwd* -y
	sudo apt purge rfdump* -y
	sudo apt purge cupp3* -y
	sudo apt purge apparmor -y
	sudo apt purge nis* -y 
	sudo apt purge ldap-utils -y
	sudo apt purge prelink -y
	sudo apt purge rsh-client rsh-redone-client* rsh-server -y
	sudo apt install apparmor -y
	sudo service apparmor start

     dpkg -l | grep "sniff" >> postrun/malware
     dpkg -l | grep "packet" >> postrun/malware
     dpkg -l | grep "wireless" >> postrun/malware
     dpkg -l | grep "pen" >> postrun/malware
     dpkg -l | grep "test" >> postrun/malware
     dpkg -l | grep "password" >> postrun/malware
     dpkg -l | grep "crack" >> postrun/malware
     dpkg -l | grep "spoof" >> postrun/malware
     dpkg -l | grep "brute" >> postrun/malware
     dpkg -l | grep "log" >> postrun/malware
     dpkg -l | grep "key" >> postrun/malware
     dpkg -l | grep "network" >> postrun/malware
     dpkg -l | grep "map" >> postrun/malware
     dpkg -l | grep "server" >> postrun/malware
     dpkg -l | grep "CVE" >> postrun/malware
     dpkg -l | grep "exploit" >> postrun/malware
}

setNoMediaFiles(){
    find / -name '*.mp3' -type f -delete
    find / -name '*.mov' -type f -delete
    find / -name '*.mp4' -type f -delete
    find / -name '*.avi' -type f -delete
    find / -name '*.mpg' -type f -delete
    find / -name '*.mpeg' -type f -delete
    find / -name '*.flac' -type f -delete
    find / -name '*.m4a' -type f -delete
    find / -name '*.flv' -type f -delete
    find / -name '*.ogg' -type f -delete
    find /home -name '*.gif' -type f -delete
    find /home -name '*.png' -type f -delete
    find /home -name '*.jpg' -type f -delete
    find /home -name '*.jpeg' -type f -delete
	find / -iname '*.m4b' -delete
	sudo find /home -iname '*.wav' -delete
	sudo find /home -iname '*.wma' -delete
	sudo find /home -iname '*.aac' -delete
	sudo find /home -iname '*.bmp' -delete
	sudo find /home -iname '*.img' -delete
	sudo find /home -iname '*.exe' -delete
	sudo find /home -iname '*.csv' -delete
	sudo find /home -iname '*.bat' -delete
	sudo find / -iname '*.xlsx' -delete
	sudo find / -iname '*.shosts' -delete
	sudo find / -iname '*.shosts.equiv' -delete
}

random(){
    dconfSettings
	echo "* hard core 0" > /etc/security/limits.conf
	echo "tmpfs /run/shm tmpfs defaults,nodev,noexec,nosuid 0 0" >> /etc/fstab
	echo "tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
	echo "tmpfs /var/tmp tmpfs defaults,nodev,noexec,nosuid 0 0" >> /etc/fstab
  	echo "proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0" >> /etc/fstab
	prelink -ua
	apt-get remove -y prelink
	systemctl mask ctrl-alt-del.target
	systemctl daemon-reload
	echo "tty1" > /etc/securetty
	echo "TMOUT=300" >> /etc/profile
	echo "readonly TMOUT" >> /etc/profile
	echo "export TMOUT" >> /etc/profile
  	echo "declare -xr TMOUT=900" > /etc/profile.d/tmout.sh
	#dont prune shit lol
	echo "" > /etc/updatedb.conf
	echo "blacklist usb-storage" >> /etc/modprobe.d/blacklist.conf
	echo "install usb-storage /bin/false" > /etc/modprobe.d/usb-storage.conf
	cat configs/environment > /etc/environment
	cat configs/control-alt-delete.conf > /etc/init/control-alt-delete.conf
	apt-fast install -y auditd > /dev/null
	auditctl -e 1
 	echo configs/auditd.conf > /etc/audit/auditd.conf
  	echo configs/audit.rules > /etc/audit/audit.rules
 	echo 0 > /proc/sys/kernel/unprivileged_userns_clone
	cat configs/sysctl.conf > /etc/sysctl.conf
	sysctl -ep
	rm -f /usr/lib/gvfs/gvfs-trash
	rm -f /usr/lib/svfs/*trash
	sudo find / -iname '*password.txt' -delete
	sudo find / -iname '*passwords.txt' -delete
	sudo find /root -iname 'user*' -delete
	sudo find / -iname 'users.csv' -delete
	sudo find / -iname 'user.csv' -delete
	sudo rm -f /usr/share/wordpress/info.php
	sudo rm -f /usr/share/wordpress/wp-admin/webroot.php
	sudo rm -f /usr/share/wordpress/index.php
	sudo rm -f /usr/share/wordpress/r57.php
	sudo rm -f /usr/share/wordpress/phpinfo.php
	sudo rm -f /var/www/html/phpinfo.php
	sudo rm -f /var/www/html/webroot.php
	sudo rm -f /var/www/html/index.php
	sudo rm -f /var/www/html/info.php
	sudo rm -f /var/www/html/r57.php
	sudo rm -f /usr/lib/gvfs/gvfs-trash
	sudo rm -f /usr/lib/gvfs/*trash
	sudo rm -f /var/timemachine
	sudo rm -f /bin/ex1t
	sudo rm -f /var/oxygen.html
}


lastChecks(){
    dmesg | grep "Kernel/User page tables isolation: enabled" && echo "patched" || echo "unpatched"

	cat /etc/default/grub | grep "selinux" && echo "check /etc/default/grub for selinux" || echo "/etc/default/grub does not disable selinux"

	cat /etc/default/grub | grep "enforcing=0" && echo "check /etc/default/grub for enforcing" || echo "/etc/default/grub does not contain enforcing=0"
}

chandiFortnite
echo "you prolly broke something stupid"