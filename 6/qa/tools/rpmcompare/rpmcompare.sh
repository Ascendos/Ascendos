#!/bin/bash
# rpmcompare.sh was tmverifyrpms.sh
# from http://mirror.centos.org/centos/4/build/distro/tmverifyrpms
# Check a set of rpms against a reference.
# Ideas from David Cox's perl script ported to bash
# creates tmverifyrpms.log in repository where it is run in the form of:
# rpmname-cmp OK|OK-PERFECT|FAIL ref:refsize +/-:sizediffabs %:sizediff%
# Where
# - refsize is the rpm -q --qf %{SIZE} of the ref rpm
# - sizediff% is the % difference between cmp and ref
# - sizediffabs is the difference in bytes
# If there are library, or file name/perm differences, create
# reports/rpm.out
#
# Version 4.1.5-CentOS
# 2007-02-27 Johnny Hughes <johnny@centos.org>
# - Modified so that it will match some of the standard file
#   extensions we use (.centos, .c4. .el4.centos) with their
#   reference counterparts w/o those extensions
# 2005-07-13 Johnny Hughes <johnny@centos.org>
# - Modified David's great script to run standalone
#   for using in CentOS compares.
# - Removed many of the features (run in background,
#   srpms maps, etc.) which are not needed in this
#   implementation of the script
#
#   You can get all of David's tmtools as a group
#   from the /tmtools directory of any taolinux
#   mirror.  See http://www.taolinux.com for details 
#
#   Thanks to David for a great script :)
#
# Version 4.1.4
# 2004-12-23 David L. Parsley <parsley@linuxjedi.org>
# - Sort rpm --requires output
# 2004-12-21 parsley@linuxjedi.org
# - Findrepo & cd there first (to run in subdirs)
# - Put error checking before the fork-to-background
# 2004-12-03 parsley@linuxjedi.org
# - Discard rpm errors
# - Fix sign error in SZDIFF
# 2004-11-30 parsley@linuxjedi.org
# - Strip (xxx) from end (ld-linux.so mainly)
# - Add checking of rpm --requires
# 2004-09-30 David L. Parsley <parsley@linuxjedi.org>
# - use mktemp -u, or files will be mode 600
# 2004-05-16 David L. Parsley <parsley@linuxjedi.org>
# - Add user & group to fingerprinting
# - Strip right-hand-side of library linkages (after =>)
# - dump stderr by default (can override locally)
# 2004-05-01 David L. Parsley <parsley@linuxjedi.org>j
# - use rpm --dump for files, can run unpriv
#set -x
#
# This has been modified to become a standalone compare tool
# by Johnny Hughes for CentOS compares on 7/13/2005
# 

# more modifications at CERN:
#  - take some input arguments to cope with different layouts, allow for several directories to compare with
#  - remove dependency on current directory, quote everything to cope with whitespace in path
#  - make "workdir" temporary.
#  - extend patterns for modified RPM names to include SL/CERN
#  - check rpm integrity+signatures
#  - summary check at end
#  - optionally skip debuginfo RPMs from comparison (since they need explicit mirroring from ftp.redhat.com)


STARTDIR=`pwd`

#This is where the reference files are
REFDIRS="$STARTDIR/REFERENCE"

#This is the directory with files to be compared
CMPDIR="$STARTDIR/COMPARE"
#Reporting goes here
RPTDIR="$STARTDIR/rpmcomparereports"

# optional: only consider a subset/pattern
RPMPATTERN='*.rpm'

# optional: want signed RPMs
RPMNEEDSIGN=
# optional: insist on this signing key
RPMGPGKEY=

# indicator that something bad was found.
GLOBALFAIL=0
# dont bother with really old RPMs
RPMAGE=
# dont bother with debuginfo
SKIPDEBUG=

# prefer getting a real mail?
MAILTO=

# SKIP report into a file?
SKIPLIST=

#percentage to use to determine if the filesize is ok
PERCENTDIFFOK=10

#log file name
LOGFILE=$RPTDIR/rpmcompare.log

rpmarch(){
	STRIPPED=${1%.rpm}
	echo ${STRIPPED##*.}
}

genfilelist(){
    rpm -qp --dump "$1" 2>/dev/null | LC_ALL=C sort | while read DUMPLINE
    do
	DUMPLINE=${DUMPLINE/ [01] [01] /TMLINESEP}
	FSYMLINK=${DUMPLINE#*TMLINESEP* }
	DUMPLINE=${DUMPLINE%TMLINESEP*}
	FILENAME="${DUMPLINE% * * * * * *}"
	REST=${DUMPLINE#$FILENAME }
	set $REST
	echo "$FILENAME mode:$4 owner:$5 group:$6 linkto:$FSYMLINK"
    done
}

comprpms(){
        CMPRPM="$1"
	REFRPM="$2"
	MODIFIED="$3"
	RPM=`basename "$CMPRPM"`
	PKGOK="OK"
	CMPRPMDIR=`mktemp -t -d cmprpm.XXXXXX`
	REFRPMDIR=`mktemp -t -d refrpm.XXXXXX`
	WORKDIR=`mktemp -t -d workdir.XXXXXX`
	REASON=""
	rm -f "$RPTDIR/$RPM.out"
	rpm2cpio "$CMPRPM" | ( cd "$CMPRPMDIR"; cpio -id --no-absolute-filenames --quiet )
	rpm2cpio "$REFRPM" | ( cd "$REFRPMDIR"; cpio -id --no-absolute-filenames --quiet )
	cd "$CMPRPMDIR"
	find . ! -type d | while read FILENAME
	do
		if [ -x "$FILENAME" -a -f "$FILENAME" ]
		then
			echo $FILENAME >> $WORKDIR/CMPDIR-libs
			ldd "$FILENAME" 2>&1 | LC_ALL=C sort >> "$WORKDIR/CMPDIR-libs"

                        # check for libraries compiled without -fPIC, SELinux issue
                        case "$FILENAME" in 
                        *.so*)
                             eu-findtextrel "$FILENAME" >& /dev/null && echo "eu-findtextrel: $FILENAME needs text relocation" >> "$WORKDIR/CMPDIR-libs"
                             ;;
                        esac
		fi
	done
	cd "$REFRPMDIR"
	find . ! -type d | while read FILENAME
	do
		if [ -x "$FILENAME" -a -f "$FILENAME" ]
		then
			echo "$FILENAME" >> "$WORKDIR/REFDIR-libs"
			ldd "$FILENAME" 2>&1 | LC_ALL=C sort >> "$WORKDIR/REFDIR-libs"

                        # check for libraries compiled without -fPIC, SELinux issue
                        case "$FILENAME" in 
                        *.so*)
                             eu-findtextrel "$FILENAME" >& /dev/null && echo "eu-findtextrel: $FILENAME needs text relocation" >> "$WORKDIR/CMPDIR-libs"
                             ;;
                        esac
		fi
	done

	genfilelist "$CMPRPM" > "$WORKDIR/CMPDIR-list"
	genfilelist "$REFRPM" > "$WORKDIR/REFDIR-list"
	diff --unified=1 "$WORKDIR/CMPDIR-list" "$WORKDIR/REFDIR-list" > "$WORKDIR/rpmdiff"
	if [ $? -eq 1 ]
	then
	    if [ "$MODIFIED" = 0 ]
	    then
		PKGOK="FAIL"
	    else
		PKGOK="WARN"
	    fi
	    REASON="$REASON fingerprints"
            RPMNAME=`basename $CMPRPM`
#	    echo "$RPMNAME:Differing file fingerprints:" >> $LOGFILE
	    echo "Differing file fingerprints:">> "$RPTDIR/$RPM.out"
	    cat "$WORKDIR/rpmdiff" >> "$RPTDIR/$RPM.out"
	fi	
	rpm -qp --requires "$CMPRPM" 2>/dev/null | LC_ALL=C sort >"$WORKDIR/CMPDIR-req"
	rpm -qp --requires "$REFRPM" 2>/dev/null | LC_ALL=C sort >"$WORKDIR/REFDIR-req"
	diff --unified=1 "$WORKDIR/CMPDIR-req" "$WORKDIR/REFDIR-req" > "$WORKDIR/reqdiff"
	if [ $? -eq 1 -a "$MODIFIED" -eq 0 ]
	then
	    if [ "$MODIFIED" = 0 ]
	    then
		PKGOK="FAIL"
	    else
		PKGOK="WARN"
	    fi

		REASON="$REASON RPM-requires"
#		echo "$CMPRPM:Differing rpm requires requirements:" >> $LOGFILE 
		echo "Differing rpm requires requirements:">> "$RPTDIR/$RPM.out"
		cat "$WORKDIR/reqdiff" >> "$RPTDIR/$RPM.out"
	fi	
	rpm -qp --scripts --triggers "$CMPRPM" 2>/dev/null | LC_ALL=C sort >"$WORKDIR/CMPDIR-scripts"
	rpm -qp --scripts --triggers "$REFRPM" 2>/dev/null | LC_ALL=C sort >"$WORKDIR/REFDIR-scripts"
	diff --unified=1 "$WORKDIR/CMPDIR-scripts" "$WORKDIR/REFDIR-scripts" > "$WORKDIR/scriptsdiff"
	if [ $? -eq 1 -a "$MODIFIED" -eq 0 ]
	then
	    if [ "$MODIFIED" = 0 ]
	    then
		PKGOK="FAIL"
	    else
		PKGOK="WARN"
	    fi

		REASON="$REASON RPM-scripts"
#		echo "$CMPRPM:Differing scripts:" >> $LOGFILE
		echo "Differing scripts :">> "$RPTDIR/$RPM.out"
		cat "$WORKDIR/scriptsdiff" >> "$RPTDIR/$RPM.out"
	fi	
	if [ -e "$WORKDIR/REFDIR-libs" ]
	then
		# Only want what it's looking for, not what it actually gets
		perl -pi -e 's/ =>.*//' "$WORKDIR/CMPDIR-libs"
		perl -pi -e 's/ =>.*//' "$WORKDIR/REFDIR-libs"
		perl -pi -e 's/ \(.*//' "$WORKDIR/CMPDIR-libs"
		perl -pi -e 's/ \(.*//' "$WORKDIR/REFDIR-libs"
		diff --unified=1 --show-function-line='^\.' "$WORKDIR/CMPDIR-libs" "$WORKDIR/REFDIR-libs" > "$WORKDIR/libdiff"
		if [ $? -eq 1 ]
		then
		    if [ "$MODIFIED" = 0 ]
		    then
			PKGOK="FAIL"
		    else
			PKGOK="WARN"
		    fi
			
			REASON="$REASON diff.libraries"
                        RPMNAME=`basename $CMPRPM`
#			echo "$RPMNAME:Differing libraries:" >> $LOGFILE
			echo "Differing libraries:">> "$RPTDIR/$RPM.out"
			cat "$WORKDIR/libdiff" >> "$RPTDIR/$RPM.out"
			echo "ldd for CMPDIR-rpm:">> "$RPTDIR/$RPM.out"
			cat "$WORKDIR/CMPDIR-libs" >> "$RPTDIR/$RPM.out"
			echo "ldd for REFDIR-rpm:">> "$RPTDIR/$RPM.out"
			cat "$WORKDIR/REFDIR-libs" >> "$RPTDIR/$RPM.out"
		fi
	fi
	if [ -e "$WORKDIR/CMPDIR-libs" ]
	then
		grep -q 'not found' "$WORKDIR/CMPDIR-libs"
		if [ $? -eq 0 ]
		then
		    if [ "$MODIFIED" = 0 ]
		    then
			PKGOK="FAIL"
		    else
			PKGOK="WARN"
		    fi
			
			REASON="$REASON missing.libraries"
#			echo "$CMPRPM:Missing libraries:" >> $LOGFILE
			echo "Missing libraries:" >> "$RPTDIR/$RPM.out"
			cat "$WORKDIR/CMPDIR-libs" >> "$RPTDIR/$RPM.out"
		fi
	fi

	rm -rf $WORKDIR CMPDIR-libs REFDIR-libs

	# MORE TESTS HERE
	CMPSIZE=`rpm -qp --qf %{SIZE} $CMPRPM 2>/dev/null`
	REFSIZE=`rpm -qp --qf %{SIZE} $REFRPM 2>/dev/null`
	SZDIFF=$(($CMPSIZE - $REFSIZE))
	ABSDIFF=$((SZDIFF<0?-$SZDIFF:$SZDIFF))
	if [ $REFSIZE -ne 0 ]
	then
		PCTDIFF=$(($ABSDIFF * 100 / $REFSIZE))
		if [ "$PCTDIFF" -gt $PERCENTDIFFOK ]
		then
		    if [ "$MODIFIED" = 0 ]
		    then
			PKGOK="FAIL"
		    else
			PKGOK="WARN"
		    fi
		    REASON="$REASON diff.size"
                    RPMNAME=`basename $CMPRPM`
#		    echo "$RPMNAME:More than $PERCENTDIFFOK % size difference (%:$PCTDIFF) to reference RPM (reference: $REFSIZE, this: $CMPSIZE)" >> $LOGFILE
		    echo "More than $PERCENTDIFFOK % size difference (%:$PCTDIFF) to reference RPM (reference: $REFSIZE, this: $CMPSIZE) " \
			>> "$RPTDIR/$RPM.out"
		fi
	else
		PCTDIFF=-0-
	fi
	if [ $PKGOK = "OK" -a $SZDIFF -eq 0 ]
	then
		PKGOK="OK-PERFECT"
	fi

	rm -rf $CMPRPMDIR $REFRPMDIR
        cd /
	if [ "$PKGOK" = "FAIL" ]
        then 
          let GLOBALFAIL++
	fi
	RESULTS="$RPM: ${PKGOK}(${REASON}) ref:$REFSIZE +/-:$SZDIFF %:$PCTDIFF"
}



# read in a config file to save ourselves from extremely-long command lines.

[ -e "/etc/sysconfig/tmverify" ] && . /etc/sysconfig/tmverify

help() {
 cat <<EOFhelp
Usage: rpmcompare.sh [-h] [-d] [-s] [-g keyid] [-a age] [-p pat] [-m address] [-r refdir1,refdir2,..] [-c cmpdir] [-l logdir]
     compare RPMs in cmpdir (default:$CMPDIR) to those in refdir (default:$REFDIRS),
     list differences into logdir (default:$RPTDIR).
     -a: only consider RPMs less than age days old
     -p: only consider RPMs that have a certain pattern, default: ${RPMPATTERN}
     -d: dont bother looking for -debuginfo RPMs
     -m: just send mail to address, no (normal) output
     -h: help
     -s: want signed RPMs
     -g: like -s, but accept only this keyid
EOFhelp
  exit 0
}

while getopts "hdsvg:r:m:c:l:w:a:p:" flag
do
  [ "$flag" == "h" ] && help
  [ "$flag" == "s" ] && RPMNEEDSIGN=1
  [ "$flag" == "g" ] && RPMGPGKEY="${OPTARG#0x}"
  [ "$flag" == "r" ] && REFDIRS="${OPTARG//,/ }"
  [ "$flag" == "c" ] && CMPDIR="${OPTARG%\/}"
  [ "$flag" == "l" ] && RPTDIR="${OPTARG%\/}"
  [ "$flag" == "p" ] && RPMPATTERN="${OPTARG}"
  [ "$flag" == "a" ] && RPMAGE="-mtime -${OPTARG}"
  [ "$flag" == "d" ] && SKIPDEBUG=1
  [ "$flag" == "m" ] && MAILTO="${OPTARG}"
done

[ -n "$RPMGPGKEY" ] && RPMNEEDSIGN=1

[ -z "$SKIPLIST" ] && SKIPLIST="$RPTDIR/.rpmcompare-skiplist"

mkdir -p "$RPTDIR"
cd "$RPTDIR"

if [ -s $LOGFILE ] ; then
  rm $LOGFILE
else
  touch $LOGFILE
fi

echo "Using ${CMPDIR} as the COMPARE DIR and ${REFDIRS} as the REFERENCE DIRS"
echo "Using ${CMPDIR} as the COMPARE DIR and ${REFDIRS} as the REFERENCE DIRS" >> $LOGFILE

# Get list of rpms to compare

for CMPRPM in `find "${CMPDIR}" -name "${RPMPATTERN}" ${RPMAGE} | sort`
do
        cd "$RPTDIR"
        CMPRPM="${CMPRPM##${CMPDIR}/}"
	echo -n "Verifying $CMPRPM ..."

	# tests done directly on the RPM, i.e. not comparing with something
	# readable?
	if [ ! -r "${CMPDIR}/$CMPRPM" ]
	then
            echo ""
	    echo "$CMPRPM FAIL(unreadable)" >> $LOGFILE
	    let GLOBALFAIL++
	    continue
	fi

	# corrupt, signed etc - try to run rpmk only once...
	verify=`rpm -Kv "${CMPDIR}/$CMPRPM" 2>&1`
	if ! echo "$verify" | grep -q "Header SHA1 digest: OK"
	then 
            echo ""
	    echo "$CMPRPM FAIL(corrupted header or not an RPM)" >> $LOGFILE
	    echo "corrupted header or not an RPM:" >> "$RPTDIR/$CMPRPM.out"
	    echo "$verify" >> "$RPTDIR/$CMPRPM.out"
	    let GLOBALFAIL++
	    continue
	fi
	echo -n "."

	if ! echo "$verify" | grep -q "MD5 digest: OK"
	then 
            echo ""
	    echo "$CMPRPM FAIL(corrupted payload)" >> $LOGFILE
	    echo "corrupted payload:" >> "$RPTDIR/$CMPRPM.out"
	    echo "$verify" >> "$RPTDIR/$CMPRPM.out"
	    let GLOBALFAIL++
	    continue
	fi
	echo -n "."

	# do we insist on signed RPMs?
	if [ -n "$RPMNEEDSIGN" ]
	then
	    if ! echo "$verify" | grep -q "Header V3 DSA signature" ||\
	       ! echo "$verify" | grep -q "V3 DSA signature"
	    then 
		echo ""
		echo "$CMPRPM FAIL(not signed)" >> $LOGFILE
		echo "not signed:" >> "$RPTDIR/$CMPRPM.out"
		echo "$verify" >> "$RPTDIR/$CMPRPM.out"
		let GLOBALFAIL++
		continue
	    fi
	    echo -n "."

	    if ! echo "$verify" | grep -q "V3 DSA signature: OK" ||\
	       ! echo "$verify" | grep -q "Header V3 DSA signature: OK"
	    then 
		echo ""
		echo "$CMPRPM FAIL(signed with unknown key or bad signature)" >> $LOGFILE
		echo "signed with unknown key or bad signature:" >> "$RPTDIR/$CMPRPM.out"
		echo "$verify" >> "$RPTDIR/$CMPRPM.out"
		let GLOBALFAIL++
		continue
	    fi
	    echo -n "."

	    # do we insist on a specific key?
	    if [ -n "$RPMGPGKEY" ]
	    then
		if ! echo "$verify" | grep -q "V3 DSA signature: OK, key ID $RPMGPGKEY" ||\
		   ! echo "$verify" | grep -q "Header V3 DSA signature: OK, key ID $RPMGPGKEY"
		then 
		    echo ""
		    echo "$CMPRPM FAIL(not signed with distro key $RPMGPGKEY)" >> $LOGFILE
		    echo "not signed with distro key $RPMGPGKEY:" >> "$RPTDIR/$CMPRPM.out"
		    echo "$verify" >> "$RPTDIR/$CMPRPM.out"
		    let GLOBALFAIL++
		    continue
		fi
		echo -n "."
	    fi
	fi

	if [ -n "$SKIPDEBUG" -a "$CMPRPM" != "${CMPRPM/-debuginfo-}" ]
	then
	    echo "skipping debuginfo"
	    continue
	fi


	# look for world-writeable files. always a bad idea
	# OK: symlinks are lrwxrwxrwx,
	#     sticky dirs are rwxrwxrwt
	#     lots of /dev/ devices are world-writeable?
	RPMWORLDWRITE=`rpm -qlvp "${CMPDIR}/$CMPRPM" | grep '^[^lcb].......w[^t]'`
	if [ -n "$RPMWORLDWRITE" ]
	then
	    echo ""
	    echo "$CMPRPM FAIL(contains world-writeable files)" >> $LOGFILE
	    echo "world-writeable files:" >> "$RPTDIR/$CMPRPM.out"
	    echo "$RPMWORLDWRITE" >> "$RPTDIR/$CMPRPM.out"
	    let GLOBALFAIL++
	    # falltrough: can still continue with comparisons
	fi


    ##################################################################
    # end of invidiual test, rest is comparisons only
    ##################################################################

	
	# try with the original-non-distro name
	REFRPM="$CMPRPM"
	for pat in .el4.centos .el5.centos .centos4 .centos .c4 .SL4 .cern .slc4 .slc .sl6 ; do
	   # should be able to use {,pattern,pattern,..} but doesn't work with bash-2
	   REFRPM="${REFRPM//${pat}/}"
	done
        # more CERN-specific RPMs go here, for things where the author cannot be bothered..
	for pat in castor- CASTOR- hwraidtools- ; do
	   # should be able to use {,pattern,pattern,..} but doesn't work with bash-2
	   REFRPM="${REFRPM//${pat}/}"
	done
	# comparisons to some upstream RPM

	for REFDIR in $REFDIRS
        do
	    # remove trailing slashes
	    REFDIR="${REFDIR%%/%}"

	    # prefer to look for exactly-named RPMs
	    if [ -e "$REFDIR/$CMPRPM" ]; then
		comprpms "$REFDIR/$CMPRPM" "$CMPDIR/$CMPRPM" 0
                echo ""
                echo $RESULTS >> $LOGFILE
		continue 2
	    
	    fi
		

	    if [ -e "$REFDIR/$REFRPM" ]; then
		echo -n "(distro tag)... "
		comprpms "$REFDIR/$REFRPM" "$CMPDIR/$CMPRPM" 1
		echo ""
		echo $RESULTS >> $LOGFILE
		continue 2
	    fi
	done

	# nothing found? error unless we have a clearly-tagged RPM
	if [ "$CMPRPM" = "$REFRPM" ]
	then
    	    echo ""
	    echo "$CMPRPM: FAIL(no match found and no distrotag)" >> $LOGFILE
	    echo "no matching reference RPM found, but $CMPRPM has no distrotag" >> "$RPTDIR/$CMPRPM.out"
	    let GLOBALFAIL++
	else
	    echo "$CMPRPM: no match found"  >> $LOGFILE
	fi
done

echo "Finished with $GLOBALFAIL errors"

#exec 1>&6

if [ "$GLOBALFAIL" -gt 0 ]
then
    if [ -n "$SKIPLIST" ]
    then
	rm -rf "$SKIPLIST"
	for badrpm in `cat $LOGFILE | grep FAIL | cut -f1 -d:`
	do
	    echo "$badrpm" >> "$SKIPLIST"
	    rpm -qp --queryformat '%{SOURCERPM}\n' "${CMPDIR}/${badrpm}" >> "$SKIPLIST"
	done
    fi

    if [ -z "$MAILTO" ]
    then
      echo "There were $GLOBALFAIL errors, see $LOGFILE:"
      cat $LOGFILE | grep FAIL
      exit 1
    else
      ( echo -e "The following RPMs have problems:\n"; cat $LOGFILE | grep FAIL | LC_ALL=C sort; echo -e "\n\nIndividual per-RPM reports are in $RPTDIR/\n\nFull summary report:\n"; cat  $LOGFILE ) | mail -s "rpmcompare.sh: $GLOBALFAIL errors found for $CMPDIR" "$MAILTO"
      exit 0
    fi
fi
