#!/bin/bash
BASEDIR="/mnt/disk5/sl6/src/6"
STATUSDIR="$BASEDIR/status"
THREADMAX=150
THREAD=0
THREADSCRIPT="$BASEDIR/scripts/build.rpms.thread.sh"
MOCKTHREADSCRIPT="$BASEDIR/scripts/build.rpms.mock.thread.sh"
#DEFAULTTAG="sl6.0-updates"
#DEFAULTTAG="sl6.1"
DEFAULTTAG="sl6.1-updates"
SLF6TAG="slf6.1"
SL6ADDEDTAG="sl6-added"
SL6CHANGEDTAG="sl6-changed"

tagversion="$DEFAULTTAG"
if [ "$1" == "SL6-ADDED" ] ; then
	tagversion="$SL6ADDEDTAG"
elif [ "$1" == "SL6-CHANGED" ] ; then
	tagversion="$SL6CHANGEDTAG"
elif [ "$1" == "SLF6" ] ; then
	tagversion="$SLF6TAG"
fi
origtagversion=$tagversion
RPMLIST=""
if [ $# -ge 1 ] ; then
	if [ -d $1 ] ; then
		RPMDIR=$1
	else
           if [ -s $1 ] ; then
		RPMDIR=BUILD
		RPMLIST=$1
	   else
        	echo "Directory  or file $1 does not exit"
		rm $scriptlockdir/$tagversion
		exit 1	
           fi
	fi
else
        RPMDIR="RHEL6"	
        echo "Using Directory $RPMDIR"
fi
scriptlockdir=/var/lock/sl6
if [ ! -d $scriptlockdir ] ; then
  mkdir -p $scriptlockdir
fi
# Check to see if we are already building for this directory
if [ -a $scriptlockdir/$tagversion ] ; then
	# there is a lock file so exit out
     echo "It appears we are already trying to build for $tagversion"
     echo "  If you this this is an error remove the file $scriptlockdir/$tagversion"
     exit 55
else
	# there is no lock file so we can continue
	touch $scriptlockdir/$tagversion
fi

RESULTDIRi386=$BASEDIR/RPMS/koji.i386/
RESULTDIRx86_64=$BASEDIR/RPMS/koji.x86_64/
if [ ! -d  $RESULTDIRi386 ] ; then mkdir -p $RESULTDIRi386 ; fi
if [ ! -d  $RESULTDIRx86_64 ] ; then mkdir -p $RESULTDIRx86_64 ; fi
if [ -z $RPMLIST ] ; then
   cd $RPMDIR
   RPMLIST=`echo *src.rpm`
   cd ..
   if [ "$RPMLIST" = "*src.rpm" ] ; then
     echo "No rpms to rebuild in $RPMDIR, exiting"
     rm $scriptlockdir/$tagversion
     exit 1
   fi
fi

if [ ! -d $STATUSDIR ]; then mkdir $STATUSDIR ; fi
if [ ! -e done.$RPMDIR ]; then mkdir done.$RPMDIR; fi
if [ ! -e working.$RPMDIR ]; then mkdir working.$RPMDIR; fi

echo "working" > $STATUSDIR/status
#echo "$RPMLIST"

for RPM in $RPMLIST
do
	SHOULDIBUILD="yes"
	MOCK="false"
	echo "-----------------------------" >>$STATUSDIR/buildlog
	echo `date` >>$STATUSDIR/buildlog
	echo "$RPM" >>$STATUSDIR/buildlog
	tagversion=$origtagversion
	if [ -s $RPMDIR/$RPM ] ; then
	     NAME=`rpm -qp --qf "%{NAME}" $RPMDIR/$RPM`
	else
	     NAME=`rpm -qp --qf "%{NAME}" $RPM`
	fi
	#############
	# Check to see if these rpms have already been done
	#############
  	if [ -f done.$RPMDIR/$RPM ] ; then
		echo "Skipping $RPM as it was already done"
		if [ -s $RPMDIR/$RPM ] ; then
			rm $RPMDIR/$RPM
			error=1 
		fi
  	fi
	#############
	# Check to see if these rpms are in changed or dont do list
	#############
	if `grep -q "===$NAME===" $BASEDIR/scripts/not.in.sl6` ; then
	  	/bin/ln -f $RPMDIR/$RPM HOLD.CUSTOM
		/bin/mv -f $RPMDIR/$RPM done.$RPMDIR/$RPM
		echo "Package $RPM is not in out release, not building"
		error=1
	elif `grep -q "===$NAME===" $BASEDIR/scripts/customized.sl6` ; then
	  	if ! [ "$tagversion" == "$SL6CHANGEDTAG" ]  && ! [ "$tagversion" == "$SLF6TAG" ]  ; then
	  		/bin/ln -f $RPMDIR/$RPM HOLD.CUSTOM
			/bin/mv -f $RPMDIR/$RPM done.$RPMDIR/$RPM
			echo "Package $RPM is a customized package, please customize "
			error=1
		fi	  
	fi
	if [ -z $error ] ; then
	   echo "Rebuilding $RPM"
	   echo "Rebuilding $RPM" >> $STATUSDIR/buildlog
		#Put special checks here
	   case "$NAME" in
	     httpd)
	     	echo "  httpd is a customized package.  Make sure you customize it."
	     ;;
#	     perl-Sys-Virt)
#	     	echo "  perl-Sys-Virt must be run on regular mock."
#		MOCK="true"
#	     ;;
	   esac # for special checks
##############
# Now we need to add the distags if needed
##############
	echo $RPM | grep -q "el6_0" 
	if [ $? = 0 ] ; then
		#tagversion=$tagversion-el6_0
		tagversion="sl6.0-updates-el6_0"
	else
		echo $RPM | grep -q "el6_1" 
		if [ $? = 0 ] ; then
			tagversion=$tagversion-el6_1
		else
			echo $RPM | grep -q "el6_2" 
			if [ $? = 0 ] ; then
				tagversion=$tagversion-el6_2
			else
				echo $RPM | grep -q "el6_3" 
				if [ $? = 0 ] ; then
					tagversion=$tagversion-el6_3
				else
					echo $RPM | grep -q "el6_4" 
					if [ $? = 0 ] ; then
						tagversion=$tagversion-el6_4
					else
						echo $RPM | grep -q "el6_5" 
						if [ $? = 0 ] ; then
							tagversion=$tagversion-el6_5
						fi
					fi
				fi
			fi
		fi
# if this else fails then we did not find a el6_* so use default
	fi

##############
# We've done all our checks
# Let's build the packages now
##############
	FOUNDTHREAD="false"
	while [ $FOUNDTHREAD == "false" ] ; do
			let THREAD=THREAD+1
			grep -q "Thread is ready" $STATUSDIR/thread.$THREAD.status
			if [ $? -eq 0 ] ; then
				echo "Starting thread $THREAD with rpm $RPM"
				echo "$RPM::$RPMDIR::$tagversion"> $STATUSDIR/thread.$THREAD.status
				if  [ $MOCK == "true" ] ; then
					sh $MOCKTHREADSCRIPT $THREAD &
				else
					sh $THREADSCRIPT $THREAD &
				fi
				FOUNDTHREAD="true"
				if [ $THREAD -ge $THREADMAX ] ; then
					THREAD=0
					date
				fi
			else
				if [ $THREAD -ge $THREADMAX ] ; then
					THREAD=0
					sleep 20
					date
				fi
			fi
	done
	sleep 5
  fi
##############
# On to the next RPM
##############
done

cat $STATUSDIR/buildlog >> $STATUSDIR/buildlog.history

touch $STATUSDIR/finished
echo "finished" > $STATUSDIR/status
tagversion=$origtagversion
rm $scriptlockdir/$tagversion
