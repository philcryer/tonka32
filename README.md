tonka32
=======

## goal
A working prototype of a script that automatically lockdowns many things in a default linux install.

Get it in run it in with this one liner:

    wget https://raw.githubusercontent.com/philcryer/tonka32/master/bin/oneshot.sh; sh oneshot.sh

By default Debian doesn't have <code>curl</code> installed, but if you do, you can use this one liner:
    
    curl https://raw.githubusercontent.com/philcryer/tonka32/master/bin/oneshot.sh | sh
    
After it runs successfully, your system will reboot and come up with all the changes listed below.

### tasks

When run, this script automatically makes many *serious changes* to the Linux install, in an effort to lock it down. Notice that this happens *without any prompts*, so you want to know what it does, to what, and how, before you run it. (testing in Vagrant is highly recommended) These days, I'm assuming you're running a VM or something immutable that is not going to be around long (it's easier to fix something in the provision and just spin out a new instance) so instead, we use this to make a best practices setup, and WHEN we need to change things later we'll just use a fresh VM. 

* diables IPv6 (override in config)
* updates package cache
* installs curl
* Remove packages with known issues
	- xinetd (NSA, Chapter 3.2.1)
	- inetd (NSA, Chapter 3.2.1)
	- tftp-server (NSA, Chapter 3.2.5)
	- ypserv (NSA, Chapter 3.2.4)
	- telnet-server (NSA, Chapter 3.2.2)
	- rsh-server (NSA, Chapter 3.2.3)
* sets up a basic firewall that ONLY allows port 22 (optional: lock down to allow access from only one IP)
* installs libpam-tmpdir, libpam-cracklib, apparmor-profiles, ntp, openssh-server that will get used/configured later
* enables apparmor in grub if it's not already, and reboots to test and enable it
	- tells rc.local to restart the script once up so it can get to the other tasks
* sets up linux auditd with a custom ruleset

### other tasks (soon) to be implemented
* ... harden ssh config
* ... Configures package management e.g. allows only signed packages
* ... configure pkg management to update security fixes automatically
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

### feedback

Is this a perfect script? No way, if you know a better way to do something or think something I've done is bad, open an [https://github.com/philcryer/tonka32/issues](issue) for it and share your thoughts, *or for bonus points*, make a [https://github.com/blog/712-pull-requests-2-0](pull request!)

### background
1) I read about some great chef recipes that auto hardened ssh and the OS for you...
* https://github.com/TelekomLabs/chef-ssh-hardening
* https://github.com/TelekomLabs?query=hardening
 
2) I found that these were influenced by some of these links
* https://wiki.archlinux.org/index.php/Sysctl
* http://www.nsa.gov/ia/_files/os/redhat/rhel5-guide-i731.pdf
* https://github.com/TelekomLabs/chef-os-hardening
* https://wiki.ubuntu.com/Security/Features
 
3) then I found another post, this about hardening at the base install
http://konstruktoid.net/2014/04/25/creating-a-baseline-ubuntu-14-04-server/
 
and then later fromt he same author
http://konstruktoid.net/2014/04/29/hardening-the-ubuntu-14-04-server-even-further/
 
4) while it's cool ppl are rolling this into chef/puppet, I want a single script I can curl -o /tmp/script|sh - and run on any system to get the hardening setup automagically. Chef/puppet could call that script to do the dirty work still, but this way tons more servers could get locked down *considerable* more. 

5) only support debian 7+ and ubuntu 14.04? (some places use centos and rhels, maybe support those, but only at 6.5)

6) witty script name TBA

### license
The MIT License (MIT)

Copyright (c) 2014 Phil Cryer (phil@philcryer.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
