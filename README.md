tonka32
=======

working prototype

gistfile1.txt
Raw
File suppressed. Click to show.
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22	
1) read about some great chef recipes that auto hardened ssh and the OS for you...
 
https://github.com/TelekomLabs/chef-ssh-hardening
https://github.com/TelekomLabs?query=hardening
 
2) these were influenced by some of these links
 
https://wiki.archlinux.org/index.php/Sysctl
http://www.nsa.gov/ia/_files/os/redhat/rhel5-guide-i731.pdfhttps://github.com/TelekomLabs/chef-os-hardening
https://wiki.ubuntu.com/Security/Features
 
3) then I found another post, this about hardening at the base install
http://konstruktoid.net/2014/04/25/creating-a-baseline-ubuntu-14-04-server/
 
and then later
http://konstruktoid.net/2014/04/29/hardening-the-ubuntu-14-04-server-even-further/
 
4) while it's cool ppl are rolling this into chef/puppet, I want a single script I can curl -o /tmp/script|sh - and run on any system to get the hardening setup automagically. Chef/puppet could call that script to do the dirty work still, but this way tons more servers could get locked down *considerable* more. 
 
5) witty script name TBA
 
6)
