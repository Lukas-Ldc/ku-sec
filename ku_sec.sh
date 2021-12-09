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
echo -e "${RED}Securing accounts - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Modifying the function to hash passwords considered secure
echo "ENCRYPT_METHOD SHA512" >> /etc/login.defs
echo "SHA_CRYPT_MIN_ROUNDS 65536" >> /etc/login.defs
#
#
echo -e "${RED}Securing files - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Changing basic permissions for files and folders in general
sed -i 's/USERGROUPS_ENAB.*.yes/USERGROUPS_ENAB no/g' /etc/login.defs
sed -i 's/UMASK.*.022/UMASK 027/g' /etc/login.defs
#Changing basic permitions for files and folders for users
echo "umask 0077" >> /etc/profile
#Removing the setuid bit of the files in setuid.conf
chmod u-s $(cat setuid.conf | sed '/^#/d') 2>/dev/null
#Adding a sticky bit to every directory accessible in writing
find / -type d \( -perm -0002 -a \! -perm -1000 \) -exec chmod o+t {} \;
#
#
echo -e "${RED}Removing unnecessary packages - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Uninstalling packages in remove.conf
apt-get remove $(cat remove.conf) -y
#
#
echo -e "${RED}Disabling unnecessary services - $(date "+%H:%M:%S %d/%m/%y")${NC}"
#Disabling services in disable.conf
systemctl disable $(cat disable.conf)
#Stoping services in disable.conf
systemctl stop $(cat disable.conf)
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
chmod 740 /etc/cron.d/autoapt.sh
#Adding in crontab the line to start the script every hour
echo "0 * * * * root sudo /etc/cron.d/autoapt.sh" >> /etc/crontab
#Restarting the cron service
systemctl restart cron.service
#
#
echo -e "${RED}END - $(date "+%H:%M:%S %d/%m/%y")${NC}"
