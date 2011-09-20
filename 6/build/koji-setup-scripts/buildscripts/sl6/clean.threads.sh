BASEDIR="/mnt/disk5/sl6/src/6"
STATUSDIR="$BASEDIR/status"
THREADMAX=300
THREAD=0

while [ $THREAD -le $THREADMAX ]
do
	echo "Cleaning thread $THREAD"
	echo "Thread is ready" > $STATUSDIR/thread.$THREAD.status
	let THREAD=THREAD+1
done
