## install method/repo/type
install 
url --url=ftp://ftp.scientificlinux.org/linux/scientific/6.0/x86_64/os/

## use non-graphical text mode for installation
text

## networking
network --bootproto=dhcp --device=eth0 --onboot=on

## disks/partitionsn
clearpart --drives=sda --all --initlabel
zerombr
part / --fstype=ext3 --size=3584 --grow --asprimary --ondisk=sda
part swap --recommended --asprimary --ondisk=sda

## bootloader
zerombr
bootloader --append="" --location=mbr --timeout=3

## security
auth --useshadow --passalgo=sha512
firewall --enabled
# e.g. allow ssh in
#firewall --enabled --port=22:tcp
rootpw --plaintext rootpassword
selinux --enforcing

## locality
keyboard us
lang en_US.UTF-8
timezone --utc US/Central

## graphics
skipx

## install-end behavior
poweroff

## install set of packages
%packages --default
@core
kernel
wget
%end

## post install script
%post

## boot eye candy 
# e.g. from fedora, may be needed
#/usr/sbin/plymouth-set-default-plugin text

## services
/sbin/chkconfig --level=3 NetworkManager
%end

# TODO: have xbuild add this section instead of maintaining here
%post --log=/root/x-run.log
cat << EOF >> /etc/rc.d/rc.local

# script instead of kept in here
wget -O /tmp/x-run http://10.0.2.2:2112/x-run
chmod +x /tmp/x-run
/tmp/x-run
EOF

%end
