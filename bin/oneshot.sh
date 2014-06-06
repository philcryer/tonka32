#!/bin/sh

url="https://github.com/philcryer/tonka32/archive/master.tar.gz"
name=`echo $url|cut -d"/" -f5`

if [ -f '/usr/bin/wget' ]; then
	wget -O /tmp/master.tar.gz $url; cd /tmp; tar -zxf master.tar.gz; cd $name-master; chmod a+x runner.sh; ./runner.sh
	exit 0
fi
if [ -f '/usr/bin/curl' ]; then
	curl -o /tmp/master.tar.gz $url; cd /tmp; tar -zxf master.tar.gz; cd $name-master; chmod a+x runner.sh; ./runner.sh
	exit 0
else
	echo "	--- FAIL ---- This script needs wget or curl installed, try again." 1>&2
	exit 1
fi

exit 0
