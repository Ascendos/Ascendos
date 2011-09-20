#
# This script downloads all new source packages and puts them in the 
# proper spot.  It then attempts to build those packages.  And it then
# starts up a script that monitors the build and sends mail when they are done.
#
# The location of where packages are downloaded from, the location where 
#  packages are downloaded to, and the method of building are different 
#  for each distribution.
#
######################
# VARIABLES
######################
FROMHOST=ftp.redhat.com
REMOTETREE=pub/redhat/linux/enterprise
LOCALTREE=/mnt/disk5/sl6/src/6/
VERSION=6
LOCALDIRS="HOLD.CUSTOM RHEL6 SRPMS done.RHEL6 done.SRPMS"
FILEDIR=downloads
MAILFILE=/tmp/download.build.mail.$VERSION


#####################
# Download from both Client and Server directories after, just in case
#####################
for PRODUCT in Client ComputeNode Server Workstation
do
  FROM=$FROMHOST/$REMOTETREE/$VERSION$PRODUCT/en/os/SRPMS/
  if [ -z $1 ] ; then
     TO=$LOCALTREE/SRPMS/
  else
     TO=$LOCALTREE/$1
  fi
  MYPWD=`pwd`
  wget -q  ftp://$FROM
  grep src.rpm index.html | cut -d\> -f2 | cut -d\< -f1 | sort | uniq > listing.names
  /bin/rm -f local.names
  for i in $LOCALDIRS
  do
      if [ -d $LOCALTREE/$i ] ; then
  	cd $LOCALTREE/$i
  	ls *.src.rpm >> $MYPWD/local.names
  	cd $MYPWD 
      else
  	#echo "$LOCALTREE/$i is not a directory"
  	exit 1
      fi
  done
  sort local.names | uniq > local.names.s
  mv -f local.names.s local.names
  comm -2 -3 listing.names local.names > download.names
  if [ -d $TO ] ; then
    cd $TO
    for i in `cat $MYPWD/download.names`
    do
  	lftp -c "set xfer:clobber no ; get ftp://$FROM/$i"
    done
  else
    #echo "$TO does not exist"
    exit 2
  fi
  cd $MYPWD
  if [ ! -d $FILEDIR ] ; then
    mkdir $FILEDIR
  fi
  mv -f download.names $FILEDIR
  mv -f listing.names $FILEDIR
  mv -f local.names $FILEDIR
  mv -f index.html $FILEDIR
done

######
# We're done downloading, now move things in place
######
##echo "ls -1 $TO"
#ls -1 $TO
RPMLIST=`ls -1 $TO`
#echo "RPMLIST"
#echo $RPMLIST
if [ "$RPMLIST" = "" ] ; then 
	#echo "No rpms downloaded"
	#echo "We are done"
	exit 0
else
	#Do the mail
	/bin/rm -f $MAILFILE
	echo "Scientific Linux 6 packages to be built:" >> $MAILFILE
	echo $RPMLIST >> $MAILFILE
	echo " " >> $MAILFILE
	
	#echo "We have the following rpms"
	#echo $RPMLIST
	ln $TO/*.rpm $LOCALTREE/RHEL6
	if [ -z $1 ] ; then
	   mv $TO/*.rpm $LOCALTREE/done.SRPMS/
	else
	   mv $TO/*.rpm $LOCALTREE/done.$1/
	fi
	# We have some packages to build
	cd $LOCALTREE > /dev/null 2>&1
	sh ./scripts/buildrpms.6.sh RHEL6 >> $MAILFILE 2>&1 
#	Not sure if we can test our rpms against the real RHEL6
#	sh ./scripts/test.buildrpms.6.sh RHEL6 >> $MAILFILE 2>&1 
	sleep 5
	/bin/mail -s "DOWNLOAD - BUILD: SL6 errata" sl-team@fnal.gov < $MAILFILE
fi
exit 0
