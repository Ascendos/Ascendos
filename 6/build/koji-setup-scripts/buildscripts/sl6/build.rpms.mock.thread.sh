#!/bin/bash
THREAD=$1
MOCKBASEDIR="/var/lib/mock/sl6.0-build"
BASEDIR="/mnt/disk5/sl6/src/6"
STATUSDIR="$BASEDIR/status"
STATUSFILE="$STATUSDIR/thread.$THREAD.status"
LOGFILE="$STATUSDIR/thread.$THREAD.log"
RESULTDIRi386=$BASEDIR/RPMS/koji.i386/
RESULTDIRx86_64=$BASEDIR/RPMS/koji.x86_64/
RPM=`cat $STATUSFILE | cut -d':' -f1`
RPMDIR=`cat $STATUSFILE | cut -d':' -f3`
TAG=`cat $STATUSFILE | cut -d':' -f5`

#echo "I AM THREAD $THREAD"
#echo " building rpm $RPM"
#echo " in directory $RPMDIR"
#echo " with tag $TAG"
if [ -f $BASEDIR/$RPMDIR/$RPM ] ; then
	#echo "   We have found $RPM"
	SUCCESS="FALSE"
	RPMNAME=`rpm -qp --nosignature --queryformat "%{NAME}" $BASEDIR/$RPMDIR/$RPM`
	RPMnvr=`rpm -qp --nosignature --queryformat "%{NAME}-%{VERSION}-%{RELEASE}" $BASEDIR/$RPMDIR/$RPM`
	MOCKRESULTDIRi386=$MOCKBASEDIR-$RPMNAME/i386/result
	MOCKRESULTDIRx86_64=$MOCKBASEDIR-$RPMNAME/x86_64/result
	echo "#########################" >> $LOGFILE
	echo $RPM >> $LOGFILE
	echo $RPMNAME >> $LOGFILE
	echo $RPMnvr >> $LOGFILE
	date >> $LOGFILE
	echo "#########################" >> $LOGFILE
	mv -v $BASEDIR/$RPMDIR/$RPM $BASEDIR/working.$RPMDIR/$RPM >> $LOGFILE
	/usr/bin/mock -r  $RPMNAME-i386 $BASEDIR/working.$RPMDIR/$RPM >> $LOGFILE 2>&1
	/usr/bin/mock -r  $RPMNAME-x86_64 $BASEDIR/working.$RPMDIR/$RPM >> $LOGFILE 2>&1
	cd $MOCKRESULTDIRi386  >> $LOGFILE
	ls *.rpm >> $LOGFILE 2>&1
	if [ $? -eq 0 ] ; then
		SUCCESS="TRUE"
		/bin/cp -fv *.rpm $RESULTDIRi386  >> $LOGFILE 2>&1
	fi
	cd $MOCKRESULTDIRx86_64  >> $LOGFILE
	ls *.rpm >> $LOGFILE 2>&1
	if [ $? -eq 0 ] ; then
		SUCCESS="TRUE"
		/bin/cp -fv *.rpm $RESULTDIRx86_64  >> $LOGFILE 2>&1
	fi
	if [ "$SUCCESS" == "TRUE" ] ; then
		ln $BASEDIR/working.$RPMDIR/$RPM $RESULTDIRi386
		ln $BASEDIR/working.$RPMDIR/$RPM $RESULTDIRx86_64		
		mv -v $BASEDIR/working.$RPMDIR/$RPM $BASEDIR/done.$RPMDIR/$RPM >> $LOGFILE 2>&1
		echo "Thread:$THREAD - rpm:$RPM - status:Success"
	else
		mv -v $BASEDIR/working.$RPMDIR/$RPM $BASEDIR/$RPMDIR/$RPM >> $LOGFILE 2>&1
		echo "Thread:$THREAD - rpm:$RPM - status:Failure"
	fi
fi
echo "Thread is ready" > $STATUSFILE

