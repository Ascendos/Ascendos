# todo: get the baseurl abstracted/factored better/cleaner elsewhere
repo --name=ascendos60 --baseurl=EL_BUILD_CACHE_ROOT/http/build.ascendos.org/linux/ascendos/6.0/os/$basearch
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
