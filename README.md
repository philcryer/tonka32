tonka32
=======

## goal
working prototype of a script I want to run and lockdown many things in a default linux install, automatically. Sample one liner...

    curl https://raw.githubusercontent.com/philcryer/tonka32/master/runner.sh|sh -
    
after that it should run, reboot and you'll have a much safer base server env

### background
1) read about some great chef recipes that auto hardened ssh and the OS for you...
 
https://github.com/TelekomLabs/chef-ssh-hardening

https://github.com/TelekomLabs?query=hardening
 
2) these were influenced by some of these links
 
https://wiki.archlinux.org/index.php/Sysctl

http://www.nsa.gov/ia/_files/os/redhat/rhel5-guide-i731.pdfhttps://github.com/TelekomLabs/chef-os-hardening

https://wiki.ubuntu.com/Security/Features
 
3) then I found another post, this about hardening at the base install
http://konstruktoid.net/2014/04/25/creating-a-baseline-ubuntu-14-04-server/
 
and then later fromt he same author
http://konstruktoid.net/2014/04/29/hardening-the-ubuntu-14-04-server-even-further/
 
4) while it's cool ppl are rolling this into chef/puppet, I want a single script I can curl -o /tmp/script|sh - and run on any system to get the hardening setup automagically. Chef/puppet could call that script to do the dirty work still, but this way tons more servers could get locked down *considerable* more. 

5) only support debian 7+ and ubuntu 14.04? (some places use centos and rhels, maybe support those, but only at 6.5)

6) witty script name TBA
