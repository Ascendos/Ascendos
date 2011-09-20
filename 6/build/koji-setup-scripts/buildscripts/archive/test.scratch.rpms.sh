cd /srv/koji/scratch/koji/
rm -f /srv/test/ascendos/*
ln task_*/*.rpm /srv/test/ascendos/
mv task_3* done
cd /srv/test/ascendos/
rm -f *debuginfo* *src.rpm
cd /srv/test/sl60/
mv *.rpm done
cd /srv/test/ascendos/
ls *.rpm | while read line; do ln -f /srv/external/scientific/6.0/os/i386/$line /srv/test/sl60/; ln -f /srv/external/scientific/6.0/os/x86_64/$line /srv/test/sl60/; done
cd /srv/scripts/
sh rpmcompare.sh -r /srv/test/sl60/ -c /srv/test/ascendos/
