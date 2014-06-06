#!/bin/bash

set -e

baseurl="https://raw.githubusercontent.com/philcryer/tonka32/"
ipv6_off="1"

echo " *** starting"; sleep 1

echo " *** checking permissions"
if [[ $EUID -ne 0 ]]; then
	echo "	--- FAIL ---- This script must be run as root (you can trust me, right?)" 1>&2
	exit 1
fi

if [[ $ipv6_off -eq 1 ]]; then
	echo " *** disabling IPV6 (override this in config above)"
	echo net.ipv6.conf.all.disable_ipv6=1 > /etc/sysctl.d/disableipv6.conf
	sed '/::/s/^/#/' /etc/hosts >/etc/dipv6-tmp;cp -a /etc/hosts /etc/hosts-backup && mv /etc/dipv6-tmp /etc/hosts
	# only if we have avahi installed...
	if [ -d '/etc/avahi' ]; then
		sed '/ipv6=yes/s/yes/no/' /etc/avahi/avahi-daemon.conf >/etc/avahi/dipv6-tmp;cp -a /etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf-backup && mv /etc/avahi/dipv6-tmp /etc/avahi/avahi-daemon.conf
	fi
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

if [ `grep -q "security=apparmor" /etc/default/grub; echo $?` == '1' ]; then
	echo " *** fix the error by putting apparmor line in grub and rebooting"
	sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/&security=apparmor /' /etc/default/grub
	update-grub
	#sed -i -e 's/exit 0//' /etc/rc.local
	sed -i -e '/exit 0/d' /etc/rc.local
	#echo "cd /tmp; ./runner.sh" >> /etc/rc.local
	echo "wget -O /tmp/runner.sh $baseurl/master/runner.sh; cd /tmp; chmod 755 runner.sh; ./runner.sh" >> /etc/rc.local
	echo "exit 0" >> /etc/rc.local
	echo " *** rebooting"
	/sbin/reboot
	exit 0
fi

echo " *** more comming soon..."
touch /tmp/runner_ran

echo " *** clean rc.local if neccessary"
sed -i -e '/wget/d' /etc/rc.local

exit 0
