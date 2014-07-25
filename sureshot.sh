#!/usr/bin/env bash

# sureshot
# --------
# You Can't, You Won't And You Don't Stop 
# You Can't, You Won't And You Don't Stop 
# You Can't, You Won't And You Don't Stop 
# Mike D Come On And Rock The Sure Shot 

set -e

# USER VARIABLES
ipv6_off="1"

# SCRIPT VARIABLES
bs="\033[1m"
be="\033[0m"

# STARTING THE GAME
clear
echo
echo -e "\033[38;5;255m\033[48;5;234m\033[1m  S U R E S H O T  \033[0m"
echo -e "\033[38;5;255m\033[48;5;234m\033[1m ----------------- \033[0m"
echo -e "\033[38;5;255m\033[48;5;234m\033[1m  server lockdown  \033[0m"
echo
if [ ! -f '/etc/issue.net' ]; then
	echo " --- FAIL --- Hey wait a minute, this is not Linux, what are you a wiseguy?"
	exit 1
	fi
echo -e " $bs*** starting on host `hostname` running `cat /etc/issue.net`$be"; sleep 1

# ROOT DOWN, I KICK IT ROOT DOWN!
echo -e " $bs*** checking permissions$be"
if [[ $EUID -ne 0 ]]; then
	echo " --- FAIL --- This script makes big changes, so it must be run as root" 1>&2
       	echo "               (read and understand what this script does before you install it)" 1>&2
	exit 1
fi

# ONLY ALLOW AUTHENTICATED PACKAGES
echo -e " $bs*** setting package manager to only allow signed packages$be"
mv etc/99dontallowunauth /etc/apt/apt.conf.d/
#* ... Configures package management e.g. allows only signed packages
#http://www.zdnet.com/blog/open-source/how-to-lock-down-linux/9665
# if rhel/centos then...
	#rpm --verify -all
#"Please read the rpm man page for information on how to interpret the output of this command." On Debian-Linux based systems, such as Mint or Ubuntu, it's more complicated. From a Bash shell you need to run the following:
	#else
#dpkg -l \*|while read s n rest; do if [ "$s" == "ii" ]; then echo $n; fi; done > ~/tmp.txt for f in `cat ~/tmp.txt`; do debsums -s -a $f; done
#apt-get install debsums
# this takes a long time... is there a better way?
#dpkg -l \*|while read s n rest; do if [ "$s" == "ii" ]; then echo $n; fi; done > ~/tmp.txt; for f in `cat ~/tmp.txt`; do debsums -s -a $f; done

# PACKAGE CACHE
echo -e " $bs*** updating package cache$be"
apt-get -yy update

# UNATTENDED/AUTOMATED UPDATES
echo -e " $bs*** setting up unattended/automated updates$be"
apt-get -yy install unattended-upgrades
mv etc/10periodic /etc/apt/apt.conf.d/
mv etc/50unattended-upgrades /etc/apt/apt.conf.d/

# IPV6
echo -e " $bs*** disabling IPV6 (override in variables section)$be"
if [[ $ipv6_off -eq 1 ]]; then
	if [ ! -f '/etc/sysctl.d/disableipv6.conf' ]; then
		echo "	> updating sysctl"
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
		echo "	> updating modprobe"
		echo "alias net-pf-10 off" >> /etc/modprobe.d/aliases.conf
		echo "alias ipv6 off" >> /etc/modprobe.d/aliases.conf
		echo "	> updating hosts file"
		sed '/::/s/^/#/' /etc/hosts >/etc/dipv6-tmp;cp -a /etc/hosts /etc/hosts-backup && mv /etc/dipv6-tmp /etc/hosts
		echo "	> updating etc/profiles"
		sed '/^ipv6/s/^/#/' /etc/protocols >/etc/protocols-tmp;cp -a /etc/protocols /etc/protocols-backup && mv /etc/protocols-tmp /etc/protocols
		if [ -d '/etc/avahi' ]; then
		echo "	> updating avahi"
			sed '/ipv6=yes/s/yes/no/' /etc/avahi/avahi-daemon.conf >/etc/avahi/dipv6-tmp;cp -a /etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf-backup && mv /etc/avahi/dipv6-tmp /etc/avahi/avahi-daemon.conf
		fi
		echo "	> updating grub to not use ipv6"
		sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/&ipv6.disable=1 /' /etc/default/grub
		echo "	> updating grub"
		update-initramfs -u
		update-grub
	fi
fi

# VULNRABLE SERVICES
echo -e " $bs*** removing known vulnerable services (these shouldn't be installed, it's freaking `date +%Y`!)$be"
	echo "	> rsh-server"
apt-get -yy purge rsh-server
	echo "	> xinetd"
apt-get -yy purge xinetd
	echo "	> tftpd"
apt-get -yy purge tftpd
	echo "	> telnetd"
apt-get -yy purge telnetd

# AUDITD
echo -e " $bs*** install auditd if it's not already installed$be"
if [ ! -f '/sbin/auditd' ]; then
	apt-get -yy install auditd audispd-plugins
	echo "	> configuring auditd"
     	cp etc/audit.rules /etc/audit/audit.rules
	echo "	> turning on auditd in grub"
	sed -i -e 's/GRUB_CMDLINE_LINUX="/&audit=1/' /etc/default/grub
	echo "	> updating grub"
	update-initramfs -u
	update-grub
	echo "	> setting to start on boot"
	update-rc.d auditd defaults
fi

# FIREWALL
echo -e " $bs*** creating a *basic* firewall, only allowing 22/80/443 by default$be"
if [ ! -f '/etc/init.d/firewall' ]; then
     	cp bin/firewall /etc/init.d/firewall
	echo "	> making script executable"
	chmod 755 /etc/init.d/firewall
	echo "	> setting to start on boot"
        update-rc.d -f firewall defaults
fi

# SECURITY PACKAGES
echo -e " $bs*** installing needed software$be"
echo "     (libpam-tmpdir, libpam-cracklib, apparmor-profiles, ntp, openssh-server)"
apt-get -yy install libpam-tmpdir libpam-cracklib ntp openssh-server

# APPARMOR
echo -e " $bs*** installing apparmor$be"
if [ `grep -q "security=apparmor" /etc/default/grub; echo $?` == '1' ]; then
	apt-get install apparmor-profiles
	echo "	> turning on apparmor in grub"
	sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/&security=apparmor /' /etc/default/grub
	echo "	> updating grub"
	update-initramfs -u
	update-grub
	echo "	> setting to start on boot"
	update-rc.d apparmor defaults
fi

# FAIL2BAN
echo -e " $bs*** install fail2ban$be"
if [ ! -f '/usr/bin/fail2ban-server' ]; then 
	apt-get install fail2ban -yy
	echo "	> configuring fail2ban to block bad ssh logins"
     	cp etc/jail.local /etc/fail2ban/jail.d/jail.local
	echo "	> setting to start on boot"
	update-rc.d fail2ban defaults
fi

echo -e " $bs*** harden kernel parameters via sysctl$be"
if [ ! -f '/etc/sysctl.d/99-tcp-ip-hardening.conf' ]; then
	echo "	> improve network performance"
	cp etc/99-tcp-ip-hardening.conf /etc/sysctl.d/
	echo "	> set dirty bytes small(er)"
 	cp etc/99-dirty-bytes.conf /etc/sysctl.d/
	echo "	> setting to start on boot"
	cp etc/99-virtual-memory-hardening.conf /etc/sysctl.d/
fi

echo -e " $bs*** install pollinate for better entrophy generation$be"
if [ ! -f '/usr/bin/pollinate' ]; then
	apt-get install pollinate; 
	echo "	> setting to start on boot"
	update-rc.d pollinate defaults
fi

echo -e " $bs*** removing suid bits$be"
	chmod -s /bin/fusermount /bin/mount /bin/su /bin/umount /usr/bin/bsd-write /usr/bin/chage /usr/bin/chfn /usr/bin/chsh /usr/bin/mlocate /usr/bin/mtr /usr/bin/newgrp /usr/bin/traceroute6.iputils /usr/bin/wall

# CLOUD_INIT
echo -e " $bs*** removing cloud init$be"
if [ ! -f '/usr/bin/cloud-init' ]; then
	apt-get purge cloud-init
	rm -rf /etc/cloud/build.info /var/lib/cloud/
fi

# CLEANUP
echo -e " $bs*** cleaning unneeded installs and downloads$be"
	echo "	> clean"
	apt-get -yy clean; 
	echo "	> autoclean"
	apt-get -yy autoclean
	echo "	> autoremove"
	apt-get -yy autoremove; 

# COMPLETE
echo -e " $bs*** all tasks completed$be"

# REBOOT (aka DROP TEST)
echo -e " $bs*** rebooting to enable all new settings and to test$be"
/sbin/reboot; echo

exit 0
