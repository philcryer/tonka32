#!/bin/bash

set -e

baseurl="https://raw.githubusercontent.com/philcryer/tonka32/"

echo " *** checking permissions"
if [[ $EUID -ne 0 ]]; then
	echo "	--- FAIL ---- This script must be run as root (you can trust me, right?)" 1>&2
	exit 1
fi

echo " *** update package cache"
apt-get -yy update

echo " *** install curl if it's not already installed"
if [ ! -f '/usr/bin/curl' ]; then
	apt-get -yy install curl
fi

echo " *** create a basic firewall, only allowing 22 by default"
if [ ! -f '/etc/init.d/firewall' ]; then
     	curl $baseurl/master/bin/firewall -o /etc/init.d/firewall
	chmod 755 /etc/init.d/firewall
	#curl $baseurl/master/etc/firewall.conf -o /etc/firewall.conf
	update-rc.d firewall defaults
fi

echo " *** install/verify we have needed software (an error is expected!)"
echo "     (libpam-tmpdir, libpam-cracklib, apparmor-profiles, ntp, openssh-server)"
apt-get -yy install libpam-tmpdir libpam-cracklib apparmor-profiles ntp openssh-server

echo " *** fix the error by putting apparmor in grub and rebooting"
if [ `grep "security=apparmor" /etc/default/grub; echo $?` == '1' ]; then
	sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/&security=apparmor /' /etc/default/grub
	update-grub
	echo "sh /tmp/runner.sh" > /etc/rc.local
	echo " *** rebooting"
	#/sbin/reboot
 fi


exit 0
