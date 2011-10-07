repo --name=ascendos60 --baseurl=http://10.0.2.2:8421/cache/build.ascendos.org___linux__ascendos__6.0/os/$basearch
lang en_US.UTF-8
keyboard us
timezone US/Central
auth --useshadow --enablemd5
selinux --enforcing
firewall --enabled
part / --size 1234



%packages
@core
anaconda-runtime
bash
kernel
passwd
policycoreutils
chkconfig
authconfig
rootfiles

%end