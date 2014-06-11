#!/bin/bash

set -e

# VARIABLES
baseurl="https://raw.githubusercontent.com/philcryer/tonka32/"
ipv6_off="1"

# PROGRAM START
echo " *** starting on host `hostname` running `cat /etc/issue.net`"; sleep 1

# ROOT CHECK
echo " *** checking permissions"
if [[ $EUID -ne 0 ]]; then
	echo " --- FAIL ---- This script makes big changes, so it must be run as root" 1>&2
       	echo "               (read and understand what this script does before you install it)" 1>&2
	exit 1
fi

# IPV6
echo " *** disabling IPV6 (override in variables section)"
if [[ $ipv6_off -eq 1 ]]; then
	#echo " *** disabling IPV6 (override in variables section)"
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
#echo " *** install curl if it's not already installed"
#if [ ! -f '/usr/bin/curl' ]; then
#	apt-get -yy install curl
#fi

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
echo " *** creating a *basic* firewall, only allowing 22/80/443 by default"
if [ ! -f '/etc/init.d/firewall' ]; then
     	#curl $baseurl/master/bin/firewall -o /etc/init.d/firewall
     	cp bin/firewall /etc/init.d/firewall
	# make executable
	chmod 755 /etc/init.d/firewall
	# start it on boot
        #update-rc.d firewall defaults
        update-rc.d firewall remove
fi

# SECURITY PACKAGES
echo " *** installing/verifying we have needed software (an error wouldn't be unexpected!)"
echo "     (libpam-tmpdir, libpam-cracklib, apparmor-profiles, ntp, openssh-server)"
apt-get -yy install libpam-tmpdir libpam-cracklib apparmor-profiles ntp openssh-server

# APPARMOR
echo " *** enabling apparmor"
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

# FAIL2BAN
echo " *** install fail2ban"
if [ ! -f '/usr/bin/fail2ban-server' ]; then 
	apt-get install fail2ban -yy
	/etc/init.d/fail2ban stop
	echo " *** making fail2ban not run as root" 
	useradd --system --no-create-home --home-dir / --groups adm fail2ban 
     	cp etc/jail.local /etc/fail2ban/jail.d/jail.local
	sed -i -e 's/FAIL2BAN_USER=root/FAIL2BAN_USER=fail2ban /' /etc/init.d/fail2ban
	sed -i -e 's/create\ 640\ root\ adm/#create\ 640\ root\ adm/' /etc/logrotate.d/fail2ban

	sed -i -e 's/#\ create\ 640\ fail2ban\ adm/create\ 640\ fail2ban\ adm/' /etc/logrotate.d/fail2ban
	###cp etc/iptables-xt_recent-echo.conf /etc/fail2ban/action.d/iptables-xt_recent-echo.conf
	####iptables -N F2B
	####iptables -A INPUT -i any -p tcp --dport 22 -j F2B
	####iptables -A INPUT -i any -p tcp --dport 22 -j ACCEPT
	####iptables -A FORWARD -i any -p tcp --dport 22 -j F2B
	####iptables -A FORWARD -i any -p tcp --dport 22 -j ACCEPT
	####iptables -A F2B -p tcp --dport 22 -m recent --update --seconds 3600 --name fail2ban-ssh -j DROP
	####iptables -A F2B -j RETURN
	chown fail2ban:adm /var/log/fail2ban.log
	update-rc.d fail2ban defaults
	/etc/init.d/fail2ban start
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
