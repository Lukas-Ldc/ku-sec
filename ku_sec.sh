#!/bin/bash
#Defining Colors
NC='\033[0m'
RED='\033[0;31m'
#
echo -e "${RED}START - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#
#
echo -e "${RED}Securing partitions - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Getting UUID of "/" mount point
uuid=`cat /etc/fstab | grep " / " | grep "UUID=" | tr -s ' ' | cut -d "=" -f 2 | cut -d ' ' -f 1`
#Getting file system type of "/"
fsys=`cat /etc/fstab | grep " / " | grep "UUID=" | tr -s ' ' | cut -d "=" -f 2 | cut -d ' ' -f 3`
#Adding fstab.conf in /etc/fstab with the right UUID and file system
cat fstab.conf | sed "s/&uuid&/${uuid}/g" | sed "s/&fsys&/${fsys}/g" >> /etc/fstab
#Mount all filesystems mentioned in fstab
mount -a
#
#
echo -e "${RED}Configuring sysctl - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Adding sysctl.conf in /etc/sysctl.conf
cat sysctl.conf >> /etc/sysctl.conf
#Loading /etc/sysctl.conf in sysctl settings
sysctl -p
#
#
echo -e "${RED}Removing unnecessary packages - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Uninstalling packages in remove.conf
apt-get remove $(cat remove.conf) -y
#
#
echo -e "${RED}Disabling unnecessary services - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Disabling services in disable.conf
while read -r l; do systemctl disable "$l"; done < disable.conf
#Stoping services in disable.conf
while read -r l; do systemctl stop "$l"; done < disable.conf
#
#
echo -e "${RED}Packages updating and cleaning - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Re-synchronize the package index files from their sources
apt-get update -y
#Install the newest versions of all packages and intelligently handles changing dependencies
apt-get dist-upgrade -y
#removes packages installed to satisfy dependencies of other packages that are no longer needed
apt-get autoremove --purge -y
#Clears out the local repository of retrieved package files
apt-get autoclean -y
#Updates all snaps in the system
snap refresh
#
#
echo -e "${RED}Automatisation of updates - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Creating autoapt.sh in /etc/crond.d/ and adding inside autoapt.conf
cat autoapt.conf > /etc/cron.d/autoapt.sh
#Making the user and the group of the file 'root'
chown root:root /etc/cron.d/autoapt.sh
#Giving the rights 'rwx' to the owner, 'r--' to the group and '---' to others
chmod 744 /etc/cron.d/autoapt.sh
#Adding in crontab the line to start the script every hour
echo "0 * * * * root sudo /etc/cron.d/autoapt.sh" >> /etc/crontab
#Restarting the cron service
systemctl restart cron.service
#
#
echo -e "${RED}END - $(date "+%H:%M:%S %d/%m/%y")${NC}"
