#!/bin/bash
OUTPUTFILE="/srv/queue/sourcerpm.date.built"
cd /srv/external/redhat/enterprise6/SRPMS
ls *.rpm | while read line
do
	rpmdate=`rpm -qp --qf "%{buildtime:date}" $line`
	echo "$line \"$rpmdate\"" >> $OUTPUTFILE
done
