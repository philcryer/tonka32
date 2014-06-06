tonka32
=======

## goal
working prototype of a script I want to run and lockdown many things in a default linux install, automatically. Sample one liner...

    wget https://raw.githubusercontent.com/philcryer/tonka32/master/oneshot.sh | sh oneshot.sh

(by default debian doesn't have curl installed (we'll install it next, but if you do/will have curl installed, you can use)
    
    curl https://raw.githubusercontent.com/philcryer/tonka32/master/oneshot.sh | sh
    
after that it should run, reboot and you'll have a much safer base server env

### tasks

When run, this script automatically makes serious changes to the Linux install, in an effort to lock it down. Notice that this happens without any prompts, so you want to know what it does, to what, and how, before you run it. These days, I'm assuming you're running a VM or something that is not going to be around for 10 years, so instead, let's make a best practices setup, then change things if we need to later and refresh on a new VM. Some task...

* diables IPv6 (override in config)
* updates package cache
* installs curl
* sets up a basic firewall that ONLY allows port 22 (optional: lock down to allow access from only one IP)
* installs libpam-tmpdir, libpam-cracklib, apparmor-profiles, ntp, openssh-server that will get used/configured later
* enables apparmor in grub if it's not already, and reboots to test and enable it
	- tells rc.local to restart the script once up so it can get to the other tasks
* ... other tasks to be implemented
* ... harden ssh config
* ... Configures package management e.g. allows only signed packages
* ... configure pkg management to update security fixes automatically
* Remove packages with known issues
	- xinetd (NSA, Chapter 3.2.1)
	- inetd (NSA, Chapter 3.2.1)
	- tftp-server (NSA, Chapter 3.2.5)
	- ypserv (NSA, Chapter 3.2.4)
	- telnet-server (NSA, Chapter 3.2.2)
	- rsh-server (NSA, Chapter 3.2.3)
* ... Configures pam and pam_limits module
* ... Shadow password suite configuration
* ... Configures system path permissions
* ... Disable core dumps via soft limits
* ... Restrict Root Logins to System Console
* ... Set SUIDs
* ... Configures kernel parameters via sysctl
	- improve network perf
	- tcp/ip stack hardening
	- virtual memory
	- set dirty bytes small
* ... add umask 077 to /etc/bash.bashrc
* ... setup host.allow and hosts.deny
* ... lock down logins.defs
* ... fix pamd sessions/config
* ... set security limits in limits.conf
* ... setup stricter fstab mount options
* ... remove suid bits
* ... setup linux auditd
	- custom rules pulled in
* 

### background
1) read about some great chef recipes that auto hardened ssh and the OS for you...
 
https://github.com/TelekomLabs/chef-ssh-hardening

https://github.com/TelekomLabs?query=hardening
 
2) these were influenced by some of these links
 
https://wiki.archlinux.org/index.php/Sysctl

http://www.nsa.gov/ia/_files/os/redhat/rhel5-guide-i731.pdf

https://github.com/TelekomLabs/chef-os-hardening

https://wiki.ubuntu.com/Security/Features
 
3) then I found another post, this about hardening at the base install
http://konstruktoid.net/2014/04/25/creating-a-baseline-ubuntu-14-04-server/
 
and then later fromt he same author
http://konstruktoid.net/2014/04/29/hardening-the-ubuntu-14-04-server-even-further/
 
4) while it's cool ppl are rolling this into chef/puppet, I want a single script I can curl -o /tmp/script|sh - and run on any system to get the hardening setup automagically. Chef/puppet could call that script to do the dirty work still, but this way tons more servers could get locked down *considerable* more. 

5) only support debian 7+ and ubuntu 14.04? (some places use centos and rhels, maybe support those, but only at 6.5)

6) witty script name TBA
