#!/bin/bash

set -e

baseurl="https://raw.githubusercontent.com/philcryer/tonka32/

echo " *** update package cache"
apt-get -yy update

echo " *** install curl if it's not already installed"
apt-get -yy install curl

echo " *** create a basic firewall, only allowing 22 by default"
if [ ! -f '/etc/init.d/firewall' ]; then
     	curl $baseurl/master/bin/firewall -o /etc/init.d/firewall
	#curl $baseurl/master/etc/firewall.conf -o /etc/firewall.conf
	update-rc.d firewall defaults
fi

echo " *** install/verify we have needed software"
echo "     (libpam-tmpdir, libpam-cracklib, apparmor-profiles, ntp, openssh-server)"
apt-get -yy install libpam-tmpdir libpam-cracklib apparmor-profiles ntp openssh-server







exit 0
