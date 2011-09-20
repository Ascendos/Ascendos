#!/bin/bash
SOURCEDIR="/srv/external/redhat/enterprise6/SRPMS"
WEEKDIR="/srv/queue/weeks"
SORTFILE="/srv/queue/sourcerpm.date.built"

cd $SOURCEDIR
ls *.rpm | while read line
do
	rpmdate=`rpm -qp --qf "%{buildtime:date}" $line`
	rpmweek=`date --date="$rpmdate" +%Y-%U`
	echo "$line $rpmweek"
	if ! [ -d $WEEKDIR/$rpmweek ] ; then
		mkdir -p $WEEKDIR/$rpmweek
	fi
	ln $line $WEEKDIR/$rpmweek/
done
