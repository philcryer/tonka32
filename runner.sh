#!/bin/bash

set -e

# VARIABLES
baseurl="https://raw.githubusercontent.com/philcryer/tonka32/"
ipv6_off="1"
bs="\033[1m"
be="\033[0m"

# STARTING
clear
echo -e " $bs***$be"
echo -e " $bs*** starting on host `hostname` running `cat /etc/issue.net`$be"; sleep 1

# ROOT DOWN, I KICK IT ROOT DOWN
echo -e " $bs*** checking permissions$be"
if [[ $EUID -ne 0 ]]; then
	echo " --- FAIL ---- This script makes big changes, so it must be run as root" 1>&2
       	echo "               (read and understand what this script does before you install it)" 1>&2
	exit 1
fi

# IPV6
echo -e " $bs*** disabling IPV6 (override in variables section)$be"
if [[ $ipv6_off -eq 1 ]]; then
	#echo " *** disabling IPV6 (override in variables section)"
	if [ ! -f '/etc/sysctl.d/disableipv6.conf' ]; then
		# tell sysctl about it
		echo "	> updating sysctl"
		echo "	> rewriting configuration files"
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
		echo "	> updating modprobe"
		echo "alias net-pf-10 off" >> /etc/modprobe.d/aliases.conf
		echo "alias ipv6 off" >> /etc/modprobe.d/aliases.conf
		# tell etc/hosts about it
		echo "	> updating hosts file"
		sed '/::/s/^/#/' /etc/hosts >/etc/dipv6-tmp;cp -a /etc/hosts /etc/hosts-backup && mv /etc/dipv6-tmp /etc/hosts
		# tell etc/protocols about it
		echo "	> updating etc/profiles"
		sed '/^ipv6/s/^/#/' /etc/protocols >/etc/protocols-tmp;cp -a /etc/protocols /etc/protocols-backup && mv /etc/protocols-tmp /etc/protocols
		# tell avahi about it (only if we have avahi installed)
		if [ -d '/etc/avahi' ]; then
		echo "	> updating avahi"
			sed '/ipv6=yes/s/yes/no/' /etc/avahi/avahi-daemon.conf >/etc/avahi/dipv6-tmp;cp -a /etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf-backup && mv /etc/avahi/dipv6-tmp /etc/avahi/avahi-daemon.conf
		fi
		# tell grub about it
		echo "	> updating grub to not use ipv6"
		sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/&ipv6.disable=1 /' /etc/default/grub
		echo "	> updating grub"
		# tell initrd to update
		update-initramfs -u
		# regenerate grub
		update-grub
	fi
fi

# PACKAGE CACHE
echo -e " $bs*** updating package cache$be"
apt-get -yy update

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
	# tell grub about it
	echo "	> configuring auditd"
     	cp etc/audit.rules /etc/audit/audit.rules
	echo "	> turning on auditd in grub"
	sed -i -e 's/GRUB_CMDLINE_LINUX="/&audit=1/' /etc/default/grub
	echo "	> updating grub"
	# tell initrd to update
	update-initramfs -u
	# regenerate grub
	update-grub
	# start it on boot
	echo "	> setting to start on boot"
	update-rc.d auditd defaults
fi

# FIREWALL
echo -e " $bs*** creating a *basic* firewall, only allowing 22/80/443 by default$be"
if [ ! -f '/etc/init.d/firewall' ]; then
     	cp bin/firewall /etc/init.d/firewall
	# make executable
	chmod 755 /etc/init.d/firewall
	# start it on boot
        #update-rc.d firewall defaults
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
	# turn on apparmor in grub
	sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/&security=apparmor /' /etc/default/grub
	echo "	> updating grub"
	# tell initrd to update
	update-initramfs -u
	# regenerate grub
	update-grub
	# start it on boot
	echo "	> setting to start on boot"
	update-rc.d apparmor defaults
fi

# FAIL2BAN
echo -e " $bs*** install fail2ban$be"
if [ ! -f '/usr/bin/fail2ban-server' ]; then 
	apt-get install fail2ban -yy
	#/etc/init.d/fail2ban stop
	#echo " *** making fail2ban not run as root" 
	#useradd --system --no-create-home --home-dir / --groups adm fail2ban 
	echo "	> configuring fail2ban to block bad ssh logins"
     	cp etc/jail.local /etc/fail2ban/jail.d/jail.local
	#sed -i -e 's/FAIL2BAN_USER=root/FAIL2BAN_USER=fail2ban /' /etc/init.d/fail2ban
	#sed -i -e 's/create\ 640\ root\ adm/#create\ 640\ root\ adm/' /etc/logrotate.d/fail2ban

	#sed -i -e 's/#\ create\ 640\ fail2ban\ adm/create\ 640\ fail2ban\ adm/' /etc/logrotate.d/fail2ban
	###cp etc/iptables-xt_recent-echo.conf /etc/fail2ban/action.d/iptables-xt_recent-echo.conf
	####iptables -N F2B
	####iptables -A INPUT -i any -p tcp --dport 22 -j F2B
	####iptables -A INPUT -i any -p tcp --dport 22 -j ACCEPT
	####iptables -A FORWARD -i any -p tcp --dport 22 -j F2B
	####iptables -A FORWARD -i any -p tcp --dport 22 -j ACCEPT
	####iptables -A F2B -p tcp --dport 22 -m recent --update --seconds 3600 --name fail2ban-ssh -j DROP
	####iptables -A F2B -j RETURN
	#chown fail2ban:adm /var/log/fail2ban.log
	echo "	> setting to start on boot"
	update-rc.d fail2ban defaults
	#/etc/init.d/fail2ban start
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

# REBOOT (aka drop test of the above changes)
echo -e " $bs*** rebooting to enable all new settings and to test$be"
/sbin/reboot; echo

exit 0
