#!/bin/bash
THREAD=$1
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
	echo "#########################" >> $LOGFILE
	echo $RPM >> $LOGFILE
	echo $RPMNAME >> $LOGFILE
	echo $RPMnvr >> $LOGFILE
	date >> $LOGFILE
	echo "#########################" >> $LOGFILE
	koji add-pkg --owner=sl-team $TAG $RPMNAME >> $LOGFILE 2>&1
	mv -v $BASEDIR/$RPMDIR/$RPM $BASEDIR/working.$RPMDIR/$RPM >> $LOGFILE
	koji build $TAG --wait $BASEDIR/working.$RPMDIR/$RPM >> $LOGFILE 2>&1
	cd $RESULTDIRi386  >> $LOGFILE
	koji download-build --debuginfo --arch=noarch --arch=i386 --arch=i686 $RPMnvr >> $LOGFILE 2>&1
	if [ $? -eq 0 ] ; then
		SUCCESS="TRUE"
	fi
	cd $RESULTDIRx86_64  >> $LOGFILE
	koji download-build --debuginfo --arch=noarch --arch=x86_64 $RPMnvr >> $LOGFILE 2>&1
	if [ $? -eq 0 ] ; then
		SUCCESS="TRUE"
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

