#!/bin/bash

set -e

# VARIABLES
baseurl="https://raw.githubusercontent.com/philcryer/tonka32/"
ipv6_off="1"

# PROGRAM START
echo " *** starting on host `hostname` which is running `cat /etc/issue.net`"; sleep 1

# ROOT CHECK
echo " *** checking permissions"
if [[ $EUID -ne 0 ]]; then
	echo " --- FAIL ---- This script must be run as root (you can trust me, right?)" 1>&2
	exit 1
fi

# IPV6
if [[ $ipv6_off -eq 1 ]]; then
	echo " *** disabling IPV6 (override in variable section)"
	if [ ! -f '/etc/sysctl.d/disableipv6.conf' ]; then
		# tell sysctl about it
		echo net.ipv6.conf.all.disable_ipv6=1 > /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.default.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.eth0.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.eth1.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.eth2.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.eth3.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.eth4.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.lo.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.vboxnet0.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.ppp0.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		echo net.ipv6.conf.tun0.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
		# tell modprobe about it
		echo "alias net-pf-10 off" >> /etc/modprobe.d/aliases.conf
		echo "alias ipv6 off" >> /etc/modprobe.d/aliases.conf
		# tell etc/hosts about it
		sed '/::/s/^/#/' /etc/hosts >/etc/dipv6-tmp;cp -a /etc/hosts /etc/hosts-backup && mv /etc/dipv6-tmp /etc/hosts
		# tell etc/protocols about it
		sed '/^ipv6/s/^/#/' /etc/protocols >/etc/protocols-tmp;cp -a /etc/protocols /etc/protocols-backup && mv /etc/protocols-tmp /etc/protocols
		# tell avahi about it (only if we have avahi installed)
		if [ -d '/etc/avahi' ]; then
			sed '/ipv6=yes/s/yes/no/' /etc/avahi/avahi-daemon.conf >/etc/avahi/dipv6-tmp;cp -a /etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf-backup && mv /etc/avahi/dipv6-tmp /etc/avahi/avahi-daemon.conf
		fi
		# tell grub about it
		sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/&ipv6.disable=1 /' /etc/default/grub
		# tell initrd to update
		update-initramfs -u
		# regenerate grub
		update-grub
	fi
fi

# PACKAGE CACHE
echo " *** updating package cache"
apt-get -yy update

# VULNRABLE SERVICES
echo " *** removing known vulnerable services (these shouldn't be installed, it's freaking `date +%Y`!)"
apt-get -yy purge rsh-server
apt-get -yy purge xinetd
apt-get -yy purge tftpd
apt-get -yy purge telnetd

# CURL
echo " *** install curl if it's not already installed"
if [ ! -f '/usr/bin/curl' ]; then
	apt-get -yy install curl
fi

# AUDITD
echo " *** install auditd if it's not already installed"
if [ ! -f '/sbin/auditd' ]; then
	 apt-get -yy install auditd audispd-plugins
	# tell grub about it
	sed -i -e 's/GRUB_CMDLINE_LINUX="/&audit=1/' /etc/default/grub
	# tell initrd to update
	update-initramfs -u
	# regenerate grub
	update-grub
	# get rules
     	#curl $baseurl/master/etc/audit.rules -o /etc/audit/audit.rules
     	cp etc/audit.rules /etc/audit/audit.rules
	# start it on boot
	update-rc.d auditd defaults
fi

# FIREWALL
echo " *** creating a *basic* firewall, only allowing 22 by default"
if [ ! -f '/etc/init.d/firewall' ]; then
     	#curl $baseurl/master/bin/firewall -o /etc/init.d/firewall
     	cp bin/firewall /etc/init.d/firewall
	# make executable
	chmod 755 /etc/init.d/firewall
	# start it on boot
	update-rc.d firewall defaults
fi

# SECURITY PACKAGES
echo " *** installing/verifying we have needed software (an error wouldn't be unexpected!)"
echo "     (libpam-tmpdir, libpam-cracklib, apparmor-profiles, ntp, openssh-server)"
apt-get -yy install libpam-tmpdir libpam-cracklib apparmor-profiles ntp openssh-server

# APPARMOR
if [ `grep -q "security=apparmor" /etc/default/grub; echo $?` == '1' ]; then
	echo " *** fix the error by putting apparmor line in grub and rebooting"
	# turn on apparmor in grub
	sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/&security=apparmor /' /etc/default/grub
	# tell initrd to update
	update-initramfs -u
	# regenerate grub
	update-grub
	# start it on boot
	update-rc.d apparmor defaults
fi

# CLEANUP
echo " *** cleaning unneeded downloads"
apt-get -yy autoremove; apt-get -yy clean; apt-get -yy autoclean

# COMPLETE
echo " *** all tasks completed"

# REBOOT (aka drop test of the above changes)
echo " *** rebooting to enable all new settings and to test"
/sbin/reboot; echo

exit 0
