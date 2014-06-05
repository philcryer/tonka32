#!/bin/bash

set -e

baseurl="https://raw.githubusercontent.com/philcryer/tonka32/"

echo " *** starting ***"

sleep 1

echo " *** checking permissions"
if [[ $EUID -ne 0 ]]; then
	echo "	--- FAIL ---- This script must be run as root (you can trust me, right?)" 1>&2
	exit 1
fi


echo " *** updating package cache"
apt-get -yy update

echo " *** install curl if it's not already installed"
if [ ! -f '/usr/bin/curl' ]; then
	apt-get -yy install curl
fi

echo " *** creating a *basic* firewall, only allowing 22 by default"
if [ ! -f '/etc/init.d/firewall' ]; then
     	curl $baseurl/master/bin/firewall -o /etc/init.d/firewall
	chmod 755 /etc/init.d/firewall
	update-rc.d firewall defaults
fi

echo " *** installing/verifying we have needed software (an error wouldn't be unexpected!)"
echo "     (libpam-tmpdir, libpam-cracklib, apparmor-profiles, ntp, openssh-server)"
apt-get -yy install libpam-tmpdir libpam-cracklib apparmor-profiles ntp openssh-server

if [ `grep "security=apparmor" /etc/default/grub; echo $?` == '1' ]; then
	echo " *** fix the error by putting apparmor line in grub and rebooting"
	sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/&security=apparmor /' /etc/default/grub
	update-grub
	sed -i -e 's/exit 0//' /etc/rc.local
	echo "cd /tmp; ./runner.sh" >> /etc/rc.local
	echo "exit 0" >> /etc/rc.local
	echo " *** rebooting"
	/sbin/reboot
fi


exit 0

