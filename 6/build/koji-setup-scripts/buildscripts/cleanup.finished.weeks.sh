#!/bin/bash
WEEKDIR="/srv/queue/weeks/"
DONEDIR="/srv/queue/weeks/done/"
BINARYDIR="/srv/queue/weeks/binary/"
NOTINDIR="/srv/queue/weeks/notinrelease/"
CUSTOMDIR="/srv/queue/weeks/custom/"
SCRIPTDIR="/srv/scripts/buildscripts/"
LOGFILE="/srv/queue/weeks/logfile"

cd $WEEKDIR
ls -d 20* | while read week
do
	echo "Week: $week"
	if ! [ -d $DONEDIR/$week ] ; then
		mkdir -p $DONEDIR/$week
	fi
	cd $WEEKDIR/$week
	ls *.rpm | while read line
	do
		cd $WEEKDIR/$week
		RPMname=`rpm -qp --nosignature --queryformat "%{NAME}" $line`
		RPMnvr=`rpm -qp --nosignature --queryformat "%{NAME}-%{VERSION}-%{RELEASE}" $line`
		# Check to see if this package is in our not.in.ascendos list
		if `grep -q "===$RPMname===" $SCRIPTDIR/not.in.asc6` ; then
			mv $WEEKDIR/$week/$line $NOTINDIR
		# Check to see if this package is in our not.in.ascendos list
		elif `grep -q "===$RPMname===" $SCRIPTDIR/customized` ; then
			mv $WEEKDIR/$week/$line $CUSTOMDIR
		# Check to see if this package is already done
		else
			cd $BINARYDIR
			koji download-build --debuginfo --arch=noarch --arch=i386 --arch=i686 --arch=x86_64 $RPMnvr >>  $LOGFILE 2>&1
			if [ $? -eq 0 ] ; then
				mv $WEEKDIR/$week/$line $DONEDIR/$week/
			fi
		fi
	done
	ls *.rpm > /dev/null 2>&1
	if [ $? -eq 2 ] ; then
		cd $WEEKDIR
		rmdir $WEEKDIR/$week
		echo "   Removed directory"
	fi
done
