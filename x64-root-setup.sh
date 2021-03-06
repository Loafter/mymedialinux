#!/bin/bash

#sudo apt-get install autoconf libgcrypt-dev  xsltproc docbook-utils gtk-doc-tools ncurses-dev bison libglib2.0-dev autogen ctags cscope protobuf-c-compiler
check_success()
{
   if [ $? -ne 0 ]
   then
      echo Failed
      exit 1
   fi
   echo Done
}
isget="$2"
InstallCoreUtils()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./coreutils
    #git clone git://git.sv.gnu.org/coreutils
    wget -c "http://ftp.gnu.org/gnu/coreutils/coreutils-8.24.tar.xz"
    tar -Jxf coreutils-8.24.tar.xz
    rm coreutils-8.24.tar.xz
fi

cd coreutils-8.24
./configure --prefix=/ --host=$HOST --build=x86_64-linux-gnu
patch ./Makefile < ../dummymake.patch
patch ./man/dummy-man < ../dummyman.patch
sed -i -e 's|#cu_install_program = ${INSTALL}|cu_install_program = ${INSTALL}|g' Makefile
sed -i -e 's|cu_install_program = src/ginstall|#cu_install_program = src/ginstall|g' Makefile
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd .. 
}


InstallBash()
{
if [ "$isget" = "get" ]
then
    wget -c "http://ftp.gnu.org/gnu/bash/bash-4.3.30.tar.gz"
    tar -xvf bash-4.3.30.tar.gz
    rm bash-4.3.30.tar.gz
fi
cd bash-4.3.30
make V=0 clean
./configure --without-bash-malloc --prefix=/ --host=$HOST #--enable-static-link
#patch execute_cmd.c <  ../bashjobcontrol.patch
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
cd $SYSROOT
ln -sf ./lib ./lib64
cd -
cd $SYSROOT/bin
ln -sf bash sh
cd -
check_success
cd ..
}

InstallInetUtils()
{

if [ "$isget" = "get" ]
then
    wget -c "http://ftp.gnu.org/gnu/inetutils/inetutils-1.9.4.tar.gz"
    tar -xvf inetutils-1.9.4.tar.gz
    rm inetutils-1.9.4.tar.gz
fi

cd inetutils-1.9.4
make V=0 clean
./configure --prefix=/ --host=$HOST CFLAGS="-I$SYSROOT/include/ -O2" \
  --disable-rlogind \
  --disable-rshd \331
  --disable-syslogd \
  --disable-talkd \
  --disable-telnetd \
  --disable-tftpd \
  --disable-uucpd \
  --disable-ftp \
  --disable-dnsdomainname \
  --disable-rcp \
  --disable-rexec \
  --disable-rlogin \
  --disable-rsh \
  --disable-logger \
  --disable-talk \
  --disable-telnet \
  --disable-tftp \
  --disable-ifconfig


patch ./ifconfig/system/linux.c < ../inetutilpathprocspath.patch
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}



InstallIproute2()
{

if [ "$isget" = "get" ]
then
    rm -rfv ./iprout*
    git clone git://git.kernel.org/pub/scm/linux/kernel/git/shemminger/iproute2.git
    
fi

cd iproute2
make V=0 clean
./configure --prefix=/ --host=$HOST
sed -i '/^TARGETS/s@arpd@@g' misc/Makefile
sed -i -e 's|PREFIX?=/usr|PREFIX=/|g' ./Makefile
make  V=0 -j 9
check_success
#make V=0 install DESTDIR=$SYSROOT
make V=0 install DESTDIR="/home/andrew/Desktop/iproute2/"
check_success
cd ..
}

InstallBridge()
{

if [ "$isget" = "get" ]
then
    rm -rfv ./bridge-utils*
    git clone git://git.kernel.org/pub/scm/linux/kernel/git/shemminger/bridge-utils.git
    
fi

cd bridge-utils
autoconf
./configure --prefix=/ --host=$HOST
make  V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}



InstallZlib()
{
if [ "$isget" = "get" ]
then
    wget -c "http://zlib.net/zlib-1.2.8.tar.gz"
    tar -xf zlib-1.2.8.tar.gz
    rm zlib-1.2.8.tar.gz 
fi
cd zlib-1.2.8
make V=0 clean
./configure --prefix=/
make V=0  -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}

InstallOpenSSl()
{

if [ "$isget" = "get" ]
then
    wget -c "http://www.openssl.org/source/openssl-1.0.2d.tar.gz"
    tar -xf openssl-1.0.2d.tar.gz
    rm openssl-1.0.2d.tar.gz
fi
#cp 1.0.1g-docfixes-diff.patch ./openssl-1.0.1g
cd openssl-1.0.2d
#patch -p1 <1.0.1g-docfixes-diff.patch
make V=0 clean
./Configure linux-elf --prefix=/ no-asm -fPIC --openssldir=/etc/ssl
make -j 9
check_success
make install INSTALL_PREFIX=$SYSROOT
check_success
cd ..
}



InstallOpenSSH()
{
if [ "$isget" = "get" ]
then
    wget -c "http://mirror.yandex.ru/pub/OpenBSD/OpenSSH/portable/openssh-7.1p1.tar.gz"
    tar -xf openssh-7.1p1.tar.gz
    rm openssh-7.1p1.tar.gz
fi

cd openssh-7.1p1
make V=0 clean
./configure --prefix=/ --host=$HOST --sysconfdir=/etc/ssh --with-pam
#
make V=0 LDFLAGS="-dynamic-linker /lib64/ld-linux-x86-64.so.2 $SYSROOT/lib/crt1.o $SYSROOT/lib/crti.o $SYSROOT/lib/crtn.o -L. -Lopenbsd-compat/ -L$SYSROOT/lib -lc -lgcc_s"  CFLAGS="-DHAVE_SETLOGIN -UHAVE_PROC_PID -fPIC -g -O2 -Wall -Wpointer-arith -Wuninitialized -Wsign-compare -Wformat-security -Wsizeof-pointer-memaccess -Wno-pointer-sign -Wno-unused-result -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -fno-builtin-memset -fstack-protector-all" -j 3
check_success  -j 9
make V=0 DESTDIR=$SYSROOT STRIP_OPT="--strip-program=x86_64-media-linux-gnu-strip" install-nokeys
check_success



mkdir -p -v "$SYSROOT/etc/ssh/"
cat > "$SYSROOT/etc/ssh/sshd_config" << "EOF"
AuthorizedKeysFile      .ssh/authorized_keys
GatewayPorts yes
PasswordAuthentication yes
PermitRootLogin yes
UsePAM yes
X11Forwarding yes
UsePrivilegeSeparation no               # Default for new installations.
Subsystem       sftp    /libexec/sftp-server

EOF

ssh-keygen -t rsa -q -f "$SYSROOT/etc/ssh/ssh_host_rsa_key"
ssh-keygen -t dsa -q -f "$SYSROOT/etc/ssh/ssh_host_dsa_key"
ssh-keygen -t ecdsa -q -f "$SYSROOT/etc/ssh/ssh_host_ecdsa_key"
cat > "$SYSROOT/lib/systemd/system/ssh.service" << "EOF"
[Unit]
Description=OpenBSD Secure Shell server
After=network.target
[Service]
ExecStartPre=/bin/mkdir -p /var/run/sshd
ExecStart=/sbin/sshd -D
KillMode=process
Restart=always
[Install]
WantedBy=multi-user.target
EOF
ln -s -v "/lib/systemd/system/ssh.service" "$SYSROOT/etc/systemd/system/multi-user.target.wants/ssh.service"

cd ..
}


InstallCurl()
{
if [ "$isget" = "get" ]
then
    wget -c "http://curl.haxx.se/download/curl-7.42.0.tar.gz"
    tar -xf curl-7.42.0.tar.gz
    rm curl-7.42.0.tar.gz
    #wget -c "http://ftp.de.debian.org/debian/pool/main/c/curl/curl_7.37.0.orig.tar.gz"
    #tar -xf curl_7.37.0.orig.tar.gz
    #rm curl_7.37.0.orig.tar.gz
fi

cd curl-7.42.0
make V=0 clean
./configure --prefix=/ --host=$HOST
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}




InstallLibEvent()
{


if [ "$isget" = "get" ]
then
    wget -c "https://github.com/downloads/libevent/libevent/libevent-2.0.21-stable.tar.gz"
    tar -xf libevent-2.0.21-stable.tar.gz
    rm libevent-2.0.21-stable.tar.gz
fi

cd libevent-2.0.21-stable
make V=0 clean
./configure --prefix=/ --host=$HOST
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}

InstallDhcp()
{
if [ "$isget" = "get" ]
then
    rm -rf ./dnsmasq
    git clone "git://thekelleys.org.uk/dnsmasq.git"
fi
cd dnsmasq
./configure --prefix=/ --host=$HOST
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}

InstallNftables()
{
if [ "$isget" = "get" ]
then
    rm -rf ./nftables
    git clone "http://git.kernel.org/pub/scm/linux/kernel/git/pablo/nftables.git"
fi
cd nftables
sh autogen.sh
./configure --prefix=/ --host=$HOST
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}


InstallTransmission()
{

if [ "$isget" = "get" ]
then
	rm -rfv Transmission    
	svn co svn://svn.transmissionbt.com/Transmission/trunk Transmission

	#wget -c "http://download-origin.transmissionbt.com/files/transmission-2.84.tar.xz"
	#tar -xf transmission-2.84.tar.xz
fi

cd Transmission
./autogen.sh
make V=0 clean
with_ssl=$SYSROOT CFLAGS="-w -O2" \
LIBEVENT_CFLAGS="-I$SYSROOT/include/curl" LIBEVENT_LIBS="-L$SYSROOT/lib/ -levent" \
LIBCURL_CFLAGS="-I$SYSROOT/include/" LIBCURL_LIBS="-L$SYSROOT/lib/ -lcurl" \
LDFLAGS="-L$SYSROOT/lib/ -lssl -ldl" \
./configure --prefix=/ --host=$HOST --disable-gtk --disable-cli --disable-libnotify --disable-nls --disable-mac --disable-wx --disable-beos
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}

InstallNcurses()
{

if [ "$isget" = "get" ]
then
    rm -rfv ./ncurses
    git clone git://ncurses.scripts.mit.edu/ncurses.git
fi

cd ncurses
make V=0 clean
./configure --prefix=/ --host=$HOST --mandir="/share"
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}

InstallNano()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./nano*
    svn co svn://svn.savannah.gnu.org/nano/trunk/nano 
    #wget -c "http://www.nano-editor.org/dist/v2.3/nano-2.3.5.tar.gz"
    #tar -xf nano-2.3.5.tar.gz
    #rm nano-2.3.5.tar.gz
fi

cd nano
./autogen.sh
mkdir buidnano
cd buidnano
rm -rfv ./*
make V=0 clean 
../configure --prefix=/ --host=$HOST CFLAGS="-I$SYSROOT/include/ncurses -DENABLE_UTF8 -O2" --datadir="/share/"
make V=0 -j 9
check_success
make install DESTDIR=$SYSROOT
check_success
cd ..
cd ..
}

InstallHtop()
{
if [ "$isget" = "get" ]
then
	rm -rfv ./htop
 	git clone https://github.com/hishamhm/htop 
fi
cd htop
aclocal -I m4
autoconf
autoheader
libtoolize --copy --force
automake --add-missing --copy
check_success
./configure --prefix=/ --host=$HOST --disable-unicode CFLAGS="-I$SYSROOT/include/ -O2"
make -j 9
check_success
make install DESTDIR=$SYSROOT
check_success
cd ..
}

InstallReadline()
{

if [ "$isget" = "get" ]
then
    wget -c "http://ftp.gnu.org/gnu/readline/readline-6.3.tar.gz"
    tar -xf readline-6.3.tar.gz
    rm readline-6.3.tar.gz
fi


cd readline-6.3
make V=0 clean
./configure --prefix=/ bash_cv_wcwidth_broken=yes --host=$HOST
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}

SoftEtherVpn()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./SoftEtherVPN
    git clone https://github.com/SoftEtherVPN/SoftEtherVPN.git
fi
cp ./Makefile ./SoftEtherVPN/
cd SoftEtherVPN
make V=0 clean
./configure --prefix=/ --host=$HOST --build=x86_64-linux-gnu

make V=0 CC=gcc \
OPTIONS_COMPILE_RELEASE="-DNDEBUG -DVPN_SPEED -DUNIX -DUNIX_LINUX -DCPU_64 -D_REENTRANT -DREENTRANT -D_THREAD_SAFE -D_THREADSAFE -DTHREAD_SAFE -DTHREADSAFE -D_FILE_OFFSET_BITS=64 -I./src/ -I./src/Cedar/ -I$SYSROOT/include -I$SYSROOT/include -I./src/Mayaqua/ -O2 -fsigned-char -m64" \
OPTIONS_LINK_RELEASE="-O2 -fsigned-char -m64 -lm -ldl -lrt -lpthread -lssl -lcrypto -lreadline -lncurses -lz"

#make V=0 CC=x86_64-media-linux-gnu-gcc \
#OPTIONS_COMPILE_RELEASE="-DNDEBUG -DVPN_SPEED -DUNIX -DUNIX_LINUX -DCPU_64 -D_REENTRANT -DREENTRANT -D_THREAD_SAFE -#D_THREADSAFE -DTHREAD_SAFE -DTHREADSAFE -D_FILE_OFFSET_BITS=64 -I./src/ -I./src/Cedar/ -I$SYSROOT/include -I$SYSROOT/#include -I./src/Mayaqua/ -O2 -fsigned-char -m64" \
#OPTIONS_LINK_RELEASE="-O2 -fsigned-char -m64 -lm -ldl -lrt -lpthread -lssl -lcrypto -lreadline -lncurses -lz"

check_success
make V=0 \
INSTALL_BINDIR=$SYSROOT/bin/ \
INSTALL_VPNSERVER_DIR=$SYSROOT/bin/binvpnserver/ \
INSTALL_VPNBRIDGE_DIR=$SYSROOT/bin/binvpnbridge/ \
INSTALL_VPNCLIENT_DIR=$SYSROOT/bin/binvpnclient/ \
INSTALL_VPNCMD_DIR=$SYSROOT/bin/binvpncmd/ \
install

sed -i -e 's|'$SYSROOT'||g' $SYSROOT/bin/vpnbridge 
sed -i -e 's|'$SYSROOT'||g' $SYSROOT/bin/vpnclient 
sed -i -e 's|'$SYSROOT'||g' $SYSROOT/bin/vpncmd 
sed -i -e 's|'$SYSROOT'||g' $SYSROOT/bin/vpnserver 
check_success
#check_success undefined reference to `EVP_MD_size'
cd ..
}





InstallStrongSwan()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./strongswan
    git clone git://git.strongswan.org/strongswan.git
fi
cd strongswan
./autogen.sh
make V=0 clean
./configure --prefix=/ --host=$HOST --enable-unity --build=x86_64-linux-gnu --enable-openssl --enable-gmp=no --enable-integrity-test --sysconfdir=/etc
check_success
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}




InstallNettle()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./nettle*
    git clone https://git.lysator.liu.se/nettle/nettle.git
    #wget -c  http://ftp.gnu.org/gnu/nettle/nettle-2.7.1.tar.gz
    #//tar -xvf nettle-2.7.1.tar.gz
fi
cd nettle
autoreconf
./configure --prefix=/ --host=$HOST --disable-openssl --enable-mini-gmp
check_success
make V=0 -j 9 LDFLAGS="-ldl"
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}

InstallGnutls()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./gnutls*
    git clone https://gitlab.com/gnutls/gnutls.git
    #wget -c  ftp://ftp.gnutls.org/gcrypt/gnutls/v3.3/gnutls-3.3.8.tar.xz
    #tar -xf gnutls-3.3.8.tar.xz	
fi
cd gnutls

make bootstrap
check_success

#sed -i -e 's|"x$crywrap" != "xno"|"x$crywrap" == "xno"|g' ./configure
./configure --prefix=/ --host=$HOST NETTLE_CFLAGS="-I$SYSROOT/include" NETTLE_LIBS="-L$SYSROOT/lib -lnettle" \
				    HOGWEED_CFLAGS="-I$SYSROOT/include" HOGWEED_LIBS="-L$SYSROOT/lib -lhogweed" --disable-nls \
				    --with-included-libtasn1 --disable-doc  --disable-openssl-compatibility \
				    --with-default-trust-store-file="/etc/ssl/ca-bundle.crt" --enable-local-libopts=yes --without-p11-kit
   	

check_success
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}



InstallOpenConnect()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./ocserv*
    git clone git://git.infradead.org/ocserv.git
    #wget -c  ftp://ftp.infradead.org/pub/ocserv/ocserv-0.8.6.tar.xz
    #tar -xvf ocserv-0.8.6.tar.xz
fi
cd ocserv
sed -i -e 's|SUBDIRS += src doc tests|SUBDIRS += src tests|g' ./Makefile.am
make autoreconf
chmod +x ./autogen.sh
./autogen.sh


#mkdir ./src/google/protobuf-c/ -pv
#cp -rfv ./src/protobuf/protobuf-c/* ./src/google/protobuf-c/
./configure --prefix=/ --host=$HOST LIBGNUTLS_CFLAGS="-I$SYSROOT/include" LIBGNUTLS_LIBS="-L$SYSROOT/lib -lgnutls" \
				    LIBREADLINE_CFLAGS="-I$SYSROOT/include/readline"  LIBREADLINE_LIBS="-L$SYSROOT/lib -lreadline -lncurses"  \
				    --enable-local-libopts=yes  --disable-systemd --without-protobuf
check_success
make AUTOGEN="autogen" -j 9
check_success
sed -i -e 's|/bin/true|autogen|g' ./doc/Makefile
make V=0 install DESTDIR=$SYSROOT 
check_success
cd ..
}




InstallGmp()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./gmp-6.0.0a
    wget -c "https://gmplib.org/download/gmp/gmp-6.0.0a.tar.bz2"
    tar -xf ./gmp-6.0.0a.tar.bz2
fi
cd gmp-6.0.0
make V=0 clean
./configure --prefix=/ --host=$HOST

check_success
make V=0 -j 9
check_success
rm -v ./doc/Makefile
touch ./doc/Makefile
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}


InstallLinux()
{
if [ "$isget" = "get" ]
then

    wget -c "https://www.kernel.org/pub/linux/kernel/v4.x/linux-$LINUX_VERSION.tar.gz"
    tar -xf linux-$LINUX_VERSION.tar.gz
    rm linux-$LINUX_VERSION.tar.gz
fi
cp ./.config ./linux-$LINUX_VERSION
cd linux-$LINUX_VERSION
make V=0 clean

export CXX="g++"
export LD="ld"
export CC="gcc"
export AR="ar"
export RANLIB="ranlib"
export STRIP="strip"
make V=0 ARCH=x86 CROSS_COMPILE="$CLFS/bin/x86_64-media-linux-gnu-" menuconfig -j 9
make V=0 ARCH=x86 CROSS_COMPILE="$CLFS/bin/x86_64-media-linux-gnu-" bzImage -j 3
check_success
export CXX="x86_64-media-linux-gnu-g++"
export LD="x86_64-media-linux-gnu-ld"
export CC="x86_64-media-linux-gnu-gcc"
export AR="x86_64-media-linux-gnu-ar"
export RANLIB="x86_64-media-linux-gnu-ranlib"
export STRIP="x86_64-media-linux-gnu-strip"
mkdir -pv $SYSROOT/boot/
cp ./arch/x86_64/boot/bzImage $SYSROOT/boot
cd ..
}

InstallInitram()
{


cd linux-$LINUX_VERSION
mkdir -p ./initramfs
cd ./initramfs

wget -c "http://www.busybox.net/downloads/binaries/latest/busybox-x86_64" && mv busybox-x86_64 busybox
cp -v busybox $SYSROOT/bin
chmod +x busybox
touch init.conf
cat > init.conf << "EOF"
dir /dev 0755 0 0
dir /root 0700 0 0
dir /bin 0755 0 0
dir /sbin 0755 0 0
dir /sys 0755 0 0
dir /proc 0755 0 0
dir /tmp 0700 0 0
dir /var 0700 0 0
dir /run 0700 0 0
dir /usr/bin 0755 0 0
dir /usr/sbin 0755 0 0

file /bin/busybox ./busybox 0755 0 0
slink /bin/sh /bin/busybox 0755 0 0
file /init ./init 0755 0 0
EOF

touch init
cat > init << "EOF"
#!/bin/sh

export PATH=/bin:/sbin:
export LD_LIBRARY_PATH=/lib:

/bin/busybox mount -n -t devtmpfs devtmpfs /dev
/bin/busybox mount -n -t proc     proc     /proc
/bin/busybox mount -n -t sysfs    sysfs    /sys
/bin/busybox mount -t tmpfs -o size=128m tmpfs /tmp

/bin/busybox mkdir /newroot
init="/lib/systemd/systemd"
newroot="/dev/sda1"
/bin/busybox mount "${newroot}" /newroot
exec /bin/busybox switch_root /newroot "${init}"
EOF
cd ../usr/
gcc gen_init_cpio.c -o gen_init_cpio
cd -
../usr/gen_init_cpio ./init.conf > initramfs
#cd $SYSROOT/..
#mv -v ./root ./realroot
#find ./ -depth -print | cpio -o --append -H newc -F initramfs
#mv -v ./realroot ./root
#cd -
cp -v initramfs $SYSROOT/boot/
cd ..
cd ..
}


InstallLibAttr()
{

if [ "$isget" = "get" ]
then
    
    wget -c "http://ftp.mirrorservice.org/sites/download.savannah.gnu.org/releases/attr/attr-2.4.47.src.tar.gz"
    tar -xf attr-2.4.47.src.tar.gz
    rm attr-2.4.47.src.tar.gz
fi

cd attr-2.4.47
make V=0 clean
./configure --prefix=/ --host=$HOST
make V=0 -j 9
check_success
make install-dev DESTDIR=$SYSROOT
check_success
cd ..
}

InstallLibCap()
{

if [ "$isget" = "get" ]
then
    
    wget -c "https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.24.tar.gz"
    tar -xf libcap-2.24.tar.gz
    rm libcap-2.24.tar.gz
fi

cd libcap-2.24
gcc ./libcap/_makenames.c -o ./libcap/_makenames -I./libcap/include/ -v
make V=0 CC="x86_64-media-linux-gnu-gcc"
check_success


make V=0 install DESTDIR=$SYSROOT RAISE_SETFCAP=no LIBDIR="$SYSROOT/lib" INCDIR="$SYSROOT/include" PKGCONFIGDIR="$SYSROOT/lib"
check_success
cp -rfv $SYSROOT/usr/share/* $SYSROOT/share/*
rm -rfv $SYSROOT/usr
cd ..
}


InstallUtillinux()
{

if [ "$isget" = "get" ]
then
    
    wget -c "https://www.kernel.org/pub/linux/utils/util-linux/v2.27/util-linux-2.27.tar.gz"
    tar -xf util-linux-2.27.tar.gz
    rm util-linux-2.27.tar.gz
fi
cd util-linux-2.27
make V=0 clean
./configure --prefix=/  --host=$HOST CFLAGS="-I$SYSROOT/include/ -I$SYSROOT/include/ncurses/ -O2" --with-ncurses --disable-makeinstall-chown --without-python
sed -i -e 's|-ltinfo|-lncurses|g' Makefile 
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT bashcompletiondir="/share/utilbashcomp"
check_success
cd ..
}



AddScratch()
{
mkdir -pv "$SYSROOT/root/"

cat > "$SYSROOT/etc/systemd/network/network" << "EOF"
[Match]
Name=*

[Network]
DHCP=yes
EOF
mv "$SYSROOT/etc/systemd/network/network" "$SYSROOT/etc/systemd/network/20-dhcp.network"


cat > "$SYSROOT/etc/passwd" << "EOF"
root:0BX.JrA2D99/6:0:0:root:/root:/bin/bash
systemd-network:!:1000:1000::/home/systemd-network:/bin/bash
EOF


cat > "$SYSROOT/etc/group" << "EOF"
root:x:0:
systemd-network:!:1000:
tty:x:1001:
dialout:x:1002:
kmem:x:1003:
input:x:1004:
video:x:1005:
audio:x:1006:
lp:x:1007:
disk:x:1008:
cdrom:x:1009:
tape:x:1010:
EOF

cat > "$SYSROOT/etc/protocols" << "EOF"
# Internet (IP) protocols
#
# Updated from http://www.iana.org/assignments/protocol-numbers and other
# sources.
# New protocols will be added on request if they have been officially
# assigned by IANA and are not historical.--without-libdl-prefix
# If you need a huge list of used numbers please install the nmap package.

ip	0	IP		# internet protocol, pseudo protocol number
#hopopt	0	HOPOPT		# IPv6 Hop-by-Hop Option [RFC1883]
icmp	1	ICMP		# internet control message protocol
igmp	2	IGMP		# Internet Group Management
ggp	3	GGP		# gateway-gateway protocol
ipencap	4	IP-ENCAP	# IP encapsulated in IP (officially ``IP'')
st	5	ST		# ST datagram mode
tcp	6	TCP		# transmission control protocol
egp	8	EGP		# exterior gateway protocol
igp	9	IGP		# any private interior gateway (Cisco)
pup	12	PUP		# PARC universal packet protocol
udp	17	UDP		# user datagram protocol
hmp	20	HMP		# host monitoring protocol
xns-idp	22	XNS-IDP		# Xerox NS IDP
rdp	27	RDP		# "reliable datagram" protocol
iso-tp4	29	ISO-TP4		# ISO Transport Protocol class 4 [RFC905]
dccp	33	DCCP		# Datagram Congestion Control Prot. [RFC4340]
xtp	36	XTP		# Xpress Transfer Protocol
ddp	37	DDP		# Datagram Delivery Protocol
idpr-cmtp 38	IDPR-CMTP	# IDPR Control Message Transport
ipv6	41	IPv6		# Internet Protocol, version 6
ipv6-route 43	IPv6-Route	# Routing Header for IPv6
ipv6-frag 44	IPv6-Frag	# Fragment Header for IPv6
idrp	45	IDRP		# Inter-Domain Routing Protocol
rsvp	46	RSVP		# Reservation Protocol
gre	47	GRE		# General Routing Encapsulation
esp	50	IPSEC-ESP	# Encap Security Payload [RFC2406]
ah	51	IPSEC-AH	# Authentication Header [RFC2402]
skip	57	SKIP		# SKIP
ipv6-icmp 58	IPv6-ICMP	# ICMP for IPv6
ipv6-nonxt 59	IPv6-NoNxt	# No Next Header for IPv6
ipv6-opts 60	IPv6-Opts	# Destination Options for IPv6
rspf	73	RSPF CPHB	# Radio Shortest Path First (officially CPHB)
vmtp	81	VMTP		# Versatile Message Transport
eigrp	88	EIGRP		# Enhanced Interior Routing Protocol (Cisco)
ospf	89	OSPFIGP		# Open Shortest Path First IGP
ospf	89	OSPFIGP		# Open Shortest Path First IGP
ax.25	93	AX.25		# AX.25 frames
ipip	94	IPIP		# IP-within-IP Encapsulation Protocol
etherip	97	ETHERIP		# Ethernet-within-IP Encapsulation [RFC3378]
encap	98	ENCAP		# Yet Another IP encapsulation [RFC1241]
#	99			# any private encryption scheme
pim	103	PIM		# Protocol Independent Multicast
ipcomp	108	IPCOMP		# IP Payload Compression Protocol
vrrp	112	VRRP		# Virtual Router Redundancy Protocol [RFC5798]
l2tp	115	L2TP		# Layer Two Tunneling Protocol [RFC2661]
isis	124	ISIS		# IS-IS over IPv4
sctp	132	SCTP		# Stream Control Transmission Protocol
fc	133	FC		# Fibre Channel
mobility-header 135 Mobility-Header # Mobility Support for IPv6 [RFC3775]
udplite	136	UDPLite		# UDP-Lite [RFC3828]
mpls-in-ip 137	MPLS-in-IP	# MPLS-in-IP [RFC4023]
manet	138			# MANET Protocols [RFC5498]
hip	139	HIP		# Host Identity Protocol
shim6	140	Shim6		# Shim6 Protocol [RFC5533]
wesp	141	WESP		# Wrapped Encapsulating Security Payload
rohc	142	ROHC		# Robust Header Compression

EOF

cat > "$SYSROOT/etc/resolv.conf" << "EOF"
nameserver 8.8.8.8
EOF



#mkdir -p "$SYSROOT/etc/systemd/system/getty@tty1.service.d"
#cat > "$SYSROOT/etc/systemd/system/getty@tty1.service.d/autologin.conf" << "EOF"
#[Service]
#ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
#EOF

cat > "$SYSROOT/root/.bash_profile" << "EOF"
export LD_LIBRARY_PATH=/lib
export PATH=/sbin:/bin:/libexec
#exec /bin/bash
#if [ -z "$DISPLAY" ] && [ $(tty) == /dev/tty1 ]; then 
#	exec /opt/startx.sh
#fi
EOF


cat > "$SYSROOT/root/fixall.sh" << "EOF"
#!/bin/bash
export LD_LIBRARY_PATH=/lib:
rm -rfv /lib/systemd/system/systemd-update-done.service
rm -rfv /lib/udev/rules.d/60-persistent-storage.rules
rm -rfv /lib/systemd/system/systemd-sysctl.service
rm -rfv /lib/systemd/system/sysinit.target.wants/systemd-update-done.service
rm -rfv /lib/systemd/system/sysinit.target.wants/systemd-sysctl.service
EOF
chmod +x $SYSROOT/root/fixall.sh


}





InstallXz()
{
#GTK-Doc-tools need install coreutils newest
#sudo apt-get install libgcrypt-dev  xsltproc docbook-utils gtk-doc-tools
if [ "$isget" = "get" ]
then
    rm -rf ./xz
    git clone http://git.tukaani.org/xz.git
fi
cd xz
./autogen.sh
make V=0 clean
./configure --prefix=/ --host=$HOST
make V=0 -j 9
check_success
make install DESTDIR=$SYSROOT
check_success
cd ..
}



InstallSystemD()
{
#GTK-Doc-tools need install coreutils newest
#sudo apt-get install libgcrypt-dev  xsltproc docbook-utils gtk-doc-tools
if [ "$isget" = "get" ]
then
    rm -rf ./systemd
    git clone "git://anongit.freedesktop.org/systemd/systemd"
fi


cd systemd
./autogen.sh
make V=0 clean

#patch ./configure < ../kmodsystemd.patch
./configure --prefix=/ --exec-prefix=/ --host="$HOST" \
--disable-gtk-doc --disable-seccomp --disable-selinux  --disable-xattr \
--disable-apparmor --disable-xz --disable-zlib --disable-pam --without-python \
--disable-acl --disable-smack --disable-gcrypt --disable-audit --disable-gudev \
--disable-elfutils --disable-libcryptsetup --disable-qrencode \
--disable-microhttpd --disable-gnutls --disable-libcurl \
--disable-libidn  --disable-quotacheck --disable-vconsole \
--disable-logind --disable-machined --disable-importd \
--disable-hostnamed --disable-timedated --disable-localed \
--disable-polkit --disable-resolved --disable-efi \
--disable-manpages --disable-hibernate --disable-tests  --disable-nls \
--disable-python-devel --disable-utmp --disable-xkbcommon \
--disable-ima --disable-blkid --disable-binfmt --disable-tmpfiles \
--disable-sysusers --disable-firstboot --disable-randomseed \
--disable-backlight --disable-rfkill --disable-timesyncd \
--disable-coredump --disable-myhostname --disable-ldconfig \
-disable-dbus \
  --disable-utmp \
  --disable-kmod \
  --disable-xkbcommon \
  --disable-blkid  \
  --disable-seccomp \
  --disable-ima \
  --disable-selinux \
  --disable-apparmor \
  --disable-xz \
  --disable-zlib \
  --enable-bzip2 \
  --disable-pam  \
  --disable-acl \
  --disable-smack \
  --disable-gcrypt \
  --disable-audit  \
  --disable-elfutils \
  --disable-libcryptsetup \
  --disable-qrencode  \
  --disable-microhttpd \
  --disable-gnutls \
  --disable-libcurl \
  --disable-libidn \
  --disable-libiptc \
  --disable-binfmt  \
  --disable-vconsole \
  --disable-quotacheck \
  --disable-tmpfiles  \
  --disable-sysusers \
  --disable-firstboot \
  --disable-randomseed \
  --disable-backlight \
  --disable-rfkill \
  --disable-logind \
  --disable-machined \
  --disable-importd \
  --disable-hostnamed \
  --disable-timedated \
  --disable-timesyncd \
  --disable-localed \
  --disable-coredump \
  --disable-polkit \
  --disable-resolved \
  --disable-efi \
  --disable-kdbus \
  --disable-myhostname \
  --disable-hwdb \
  --disable-manpages  \
  --disable-hibernate \
  --disable-ldconfig \
  --disable-tests  \
--with-rootprefix="/" \
--with-dbuspolicydir="/etc/" \
--with-dbussystemservicedir="/etc/" \
--with-bashcompletiondir="/etc/bash-completion" \
MOUNT_CFLAGS="-I$SYSROOT/include/libmount" \
MOUNT_LIBS="-L$SYSROOT/lib/ -lmount" \

rm -rfv $SYSROOT/lib/libmount.la
make -j 9
check_success
make install DESTDIR=$SYSROOT #LN_S="/local/bin/ln -s"
sed -i -e 's|ProtectSystem=full||g' $SYSROOT/lib/systemd/system/systemd-networkd.service
check_success
cd ..
}

CreatePkgShadow()
{
if [ "$isget" = "get" ]
then

    wget -c "http://pkg-shadow.alioth.debian.org/releases/shadow-4.2.1.tar.xz"
    tar -xf shadow-4.2.1.tar.xz
    rm shadow-4.2.1.tar.xz
   
fi
cd shadow-4.2.1
./configure --prefix=/ --host=$HOST --without-attr
make V=0 
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}


InstallKmod()
{
#sudo apt-get install gtk-doc-tools
if [ "$isget" = "get" ]
then
    rm -rf ./kmod/*
    git clone "git://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git"
fi
cd kmod
./autogen.sh --disable-gtk-doc
./configure --prefix=/ --host=$HOST --with-bashcompletiondir="/etc/bash-completion"
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
check_success
cd ..
}
InstallXbmc()
{
# pattern  \(([^)]*)\)
mkdir xbmc
cd xbmc
rm -rvf /home/andrew/Desktop/x64src/xbmc/*
mkdir -p /home/andrew/Desktop/x64src/xbmc/apt/{archive,cache}
touch /home/andrew/Desktop/x64src/xbmc/apt/status

apt-get update -o Dir::State::status="/home/andrew/Desktop/x64src/xbmc/apt/status" -o Dir::Archive="/home/andrew/Desktop/x64src/xbmc/apt/archive" -o Debug::NoLocking=True -o APT::Architecture=amd64 -o Dir::Cache=/home/andrew/Desktop/x64src/xbmc/apt/cache


apt-get install -q -y -d -o Dir::State::status="/home/andrew/Desktop/x64src/xbmc/apt/status" -o Dir::Archive="/home/andrew/Desktop/x64src/xbmc/apt/archive" -o Debug::NoLocking=True -o APT::Architecture=amd64 -o Dir::Cache=/home/andrew/Desktop/x64src/xbmc/apt/cache bash
apt-get install -q -y -d -o Dir::State::status="/home/andrew/Desktop/x64src/xbmc/apt/status" -o Dir::Archive="/home/andrew/Desktop/x64src/xbmc/apt/archive" -o Debug::NoLocking=True -o APT::Architecture=amd64 -o Dir::Cache=/home/andrew/Desktop/x64src/xbmc/apt/cache xorg
apt-get install -q -y -d -o Dir::State::status="/home/andrew/Desktop/x64src/xbmc/apt/status" -o Dir::Archive="/home/andrew/Desktop/x64src/xbmc/apt/archive" -o Debug::NoLocking=True -o APT::Architecture=amd64 -o Dir::Cache=/home/andrew/Desktop/x64src/xbmc/apt/cache xserver-xorg-input-kbd
apt-get install -q -y -d -o Dir::State::status="/home/andrew/Desktop/x64src/xbmc/apt/status" -o Dir::Archive="/home/andrew/Desktop/x64src/xbmc/apt/archive" -o Debug::NoLocking=True -o APT::Architecture=amd64 -o Dir::Cache=/home/andrew/Desktop/x64src/xbmc/apt/cache xfce4
apt-get install -q -y -d -o Dir::State::status="/home/andrew/Desktop/x64src/xbmc/apt/status" -o Dir::Archive="/home/andrew/Desktop/x64src/xbmc/apt/archive" -o Debug::NoLocking=True -o APT::Architecture=amd64 -o Dir::Cache=/home/andrew/Desktop/x64src/xbmc/apt/cache xbmc
apt-get install -q -y -d -o Dir::State::status="/home/andrew/Desktop/x64src/xbmc/apt/status" -o Dir::Archive="/home/andrew/Desktop/x64src/xbmc/apt/archive" -o Debug::NoLocking=True -o APT::Architecture=amd64 -o Dir::Cache=/home/andrew/Desktop/x64src/xbmc/apt/cache libgl1-mesa-glx
apt-get install -q -y -d -o Dir::State::status="/home/andrew/Desktop/x64src/xbmc/apt/status" -o Dir::Archive="/home/andrew/Desktop/x64src/xbmc/apt/archive" -o Debug::NoLocking=True -o APT::Architecture=amd64 -o Dir::Cache=/home/andrew/Desktop/x64src/xbmc/apt/cache grep
apt-get install -q -y -d -o Dir::State::status="/home/andrew/Desktop/x64src/xbmc/apt/status" -o Dir::Archive="/home/andrew/Desktop/x64src/xbmc/apt/archive" -o Debug::NoLocking=True -o APT::Architecture=amd64 -o Dir::Cache=/home/andrew/Desktop/x64src/xbmc/apt/cache alsa-utils libasound2

mv -v ./apt/cache/archives/* ./
FILES=./*
mkdir $SYSROOT/opt
for f in $FILES
do
  echo "Processing $f file..."
  dpkg-deb -x "./$f" "$SYSROOT/opt"  
done
mkdir -pv "$SYSROOT/opt/dev/pts"
mkdir -pv "$SYSROOT/opt/proc"
mkdir -pv "$SYSROOT/opt/sys"
mkdir -pv "$SYSROOT/opt/tmp"
mkdir -pv "$SYSROOT/opt/var"
mkdir -pv "$SYSROOT/opt/root"

cd "$SYSROOT/opt/bin/" 
ln -s bash sh
cd -

ln -sf "/usr/bin/Xorg" "$SYSROOT/opt/etc/X11/X"


cat > "$SYSROOT/opt/mountchroot" << "EOF"
#!/bin/sh
echo 1 > /proc/sys/net/ipv4/ip_forward
export PATH=/bin:/usr/bin:/sbin:/usr/sbin
export LD_LIBRARY_PATH=/lib:/usr/lib:/lib64:/usr/lib64:/usr/lib/x86_64-linux-gnu/mesa/
mount --bind /proc /opt/proc
mount --bind /dev /opt/dev
mount -t devpts none /opt/dev/pts
mount --bind /sys /opt/sys
mount --bind /tmp /opt/tmp
mount --bind /root/Downloads /opt/root/Downloads
EOF
chmod +x "$SYSROOT/opt/mountchroot"


cat > "$SYSROOT/opt/startx.sh" << "EOF"
#!/bin/sh
export PATH=/bin:/usr/bin:/sbin:/usr/sbin
export LD_LIBRARY_PATH=/lib:/usr/lib:/lib64:/usr/lib64:/usr/lib/x86_64-linux-gnu/mesa/
chroot /opt/ startx
EOF
chmod +x "$SYSROOT/opt/startx.sh"
cat > "$SYSROOT/opt/root/.xinitrc" << "EOF"
#!/bin/sh
exec xbmc
EOF
chmod +x $SYSROOT/opt/root/.xinitrc

cat > "$SYSROOT/opt/etc/X11/xorg.conf" << "EOF"
Section "ServerLayout"
	Identifier     "X.org Configured"
	Screen      0  "Screen0" 0 0
	InputDevice    "Mouse0" "CorePointer"
	InputDevice    "Keyboard0" "CoreKeyboard"
EndSection

Section "ServerFlags"
    Option "AutoAddDevices" "False"
    Option "AllowEmptyInput" "False"
EndSection

Section "Files"
	ModulePath   "/usr/lib/xorg/modules"
	FontPath     "/usr/share/fonts/X11/misc"
	FontPath     "/usr/share/fonts/X11/cyrillic"
	FontPath     "/usr/share/fonts/X11/100dpi/:unscaled"
	FontPath     "/usr/share/fonts/X11/75dpi/:unscaled"
	FontPath     "/usr/share/fonts/X11/Type1"
	FontPath     "/usr/share/fonts/X11/100dpi"
	FontPath     "/usr/share/fonts/X11/75dpi"
	FontPath     "/var/lib/defoma/x-ttcidfont-conf.d/dirs/TrueType"
	FontPath     "built-ins"
EndSection

Section "Module"
	Load  "glx"
	Load  "record"
	Load  "extmod"
	Load  "dri2"
	Load  "dbe"
	Load  "dri"
EndSection

Section "InputDevice"
	Identifier  "Keyboard0"
	Driver      "kbd"
EndSection

Section "InputDevice"
	Identifier  "Mouse0"
	Driver      "mouse"
	Option	    "Protocol" "auto"
	Option	    "Device" "/dev/input/mice"
	Option	    "ZAxisMapping" "4 5 6 7"
EndSection

Section "Monitor"
	Identifier   "Monitor0"
	VendorName   "Monitor Vendor"
	ModelName    "Monitor Model"
EndSection

Section "Device"
        ### Available Driver options are:-
        ### Values: <i>: integer, <f>: float, <bool>: "True"/"False",
        ### <string>: "String", <freq>: "<f> Hz/kHz/MHz",
        ### <percent>: "<f>%"
        ### [arg]: arg optional
        #Option     "DRI"                	# [<bool>]
        #Option     "ColorKey"           	# <i>
        #Option     "VideoKey"           	# <i>
        #Option     "FallbackDebug"      	# [<bool>]
        #Option     "Tiling"             	# [<bool>]
        #Option     "LinearFramebuffer"  	# [<bool>]
        #Option     "Shadow"             	# [<bool>]
        #Option     "SwapbuffersWait"    	# [<bool>]
        #Option     "TripleBuffer"       	# [<bool>]
        #Option     "XvMC"               	# [<bool>]
        #Option     "XvPreferOverlay"    	# [<bool>]
        #Option     "DebugFlushBatches"  	# [<bool>]
        #Option     "DebugFlushCaches"   	# [<bool>]
        #Option     "DebugWait"          	# [<bool>]
        #Option     "HotPlug"            	# [<bool>]
        #Option     "RelaxedFencing"     	# [<bool>]
	Identifier  "Card0"
	Driver      "intel"
	BusID       "PCI:0:2:0"
EndSection

Section "Device"
        ### Available Driver options are:-
        ### Values: <i>: integer, <f>: float, <bool>: "True"/"False",
        ### <string>: "String", <freq>: "<f> Hz/kHz/MHz",
        ### <percent>: "<f>%"
        ### [arg]: arg optional
        #Option     "ShadowFB"           	# [<bool>]
        #Option     "Rotate"             	# <str>
        #Option     "fbdev"              	# <str>
        #Option     "debug"              	# [<bool>]
	Identifier  "Card"
	Driver      "fbdev"
	BusID       "PCI:1:0:0"
EndSection


Section "Screen"
	Identifier "Screen0"
	Device     "Card0"
	Monitor    "Monitor0"
	SubSection "Display"
		Viewport   0 0
		Depth     1
	EndSubSection
	SubSection "Display"
		Viewport   0 0
		Depth     4
	EndSubSection
	SubSection "Display"
		Viewport   0 0
		Depth     8
	EndSubSection
	SubSection "Display"
		Viewport   0 0
		Depth     15
	EndSubSection
	SubSection "Display"
		Viewport   0 0
		Depth     16
	EndSubSection
	SubSection "Display"
		Viewport   0 0
		Depth     24
	EndSubSection
EndSection
EOF

cp -v "$SYSROOT/etc/protocols" "$SYSROOT/opt/etc/"
cp -v "$SYSROOT/etc/resolv.conf"  "$SYSROOT/opt/etc/"
cd ..
}




CreateQemuImage()
{
mkdir -p $SYSROOT/../x64image
cd $SYSROOT/../x64image
rm -vf disk.img
qemu-img create -f raw disk.img 1200M
mkfs.ext4 -F disk.img
mkdir fs
sudo mount -o loop disk.img ./fs/ 
sudo cp -rfv $SYSROOT/* ./fs/
sudo cp -rfv $SYSROOT/boot/* ./
sudo umount ./fs/
cd -
#sudo qemu-system-x86_nvidia opensorce driver64 -kernel ./bzImage -initrd ./initramfs -serial stdio -append "root=/dev/ram0 console=ttyAMA0  console=ttyS0" -hda ./disk.img
}

InstallPCRE()
{

if [ "$isget" = "get" ]
then
    rm -rfv ./pcre
    svn co svn://vcs.exim.org/pcre/code/trunk pcre
fi

cd pcre
./autogen.sh

./configure --prefix=/ --host=$HOST
make V=0 LDFLAGS="-Wl,-rpath=./.libs" -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
sed -i -e 's|prefix=|''prefix='$SYSROOT'/|g' $SYSROOT/bin/pcre-config
check_success
cd ..
}

InstallApr()
{
if [ "$isget" = "get" ]
then
     rm -rfv ./apr-1.5.1 
    wget -c  "http://apache-mirror.rbc.ru/pub/apache//apr/apr-1.5.1.tar.gz"
    tar -xvf apr-1.5.1.tar.gz
    rm apr-1.5.1.tar.gz
   
fi
cd apr-1.5.1
make V=0 clean

./configure --prefix=/ --host=$HOST ac_cv_file__dev_zero=yes ac_cv_func_setpgrp_void=yes apr_cv_tcp_nodelay_with_cork=no apr_cv_process_shared_works=no apr_cv_mutex_robust_shared=no ac_cv_sizeof_struct_iovec=8 apr_cv_mutex_recurive=yes
sed -i -e 's|$(LINK_PROG) $(OBJECTS_gen_test_char) $(ALL_LIBS)|gcc $(top_srcdir)/tools/gen_test_char.c  -o $(top_srcdir)/tools/gen_test_char|g' Makefile
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
cp -v ./apr-1-config  $SYSROOT/bin/
rm -rfv $SYSROOT/build-1
check_success
cd ..
}


InstallAprTool()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./apr-util-1.5.4
    wget -c "http://apache-mirror.rbc.ru/pub/apache//apr/apr-util-1.5.4.tar.gz"
    tar -xvf apr-util-1.5.4.tar.gz
    rm apr-util-1.5.4.tar.gz
   
fi
cd apr-util-1.5.4
cp ../apr-1.5.0/build/apr_rules.mk ./build/rules.mk
sed -i -e 's|^CFLAGS=|''CFLAGS=-I'$SYSROOT'/include/apr-1/|g' ./build/rules.mk
./configure --prefix=/ --host=$HOST --with-apr=$SYSROOT --with-openssl=$SYSROOT
make -j 9
check_success
make install DESTDIR=$SYSROOT
cp -v ./apu-1-config  $SYSROOT/bin/
check_success
cd ..
}


InstallApache()
{
if [ "$isget" = "get" ]
then
    rm -rfv ./httpd-2.4.10/*
    wget -c "https://www.apache.org/dist/httpd/httpd-2.4.10.tar.gz"
    tar -xf httpd-2.4.10.tar.gz
    rm httpd-2.4.10.tar.gz
fi

cd httpd-2.4.10
./configure --prefix=/ --with-apr-util="$SYSROOT/bin/apu-1-config"   --with-apr="$SYSROOT/bin/apr-1-config" --with-pcre="$SYSROOT/bin/pcre-config" \
--bindir=/bin \
--sysconfdir=/etc \
--libexecdir=/lib/apache \
--datadir="/share" --mandir="/share/man"
make V=0 -j 9
check_success
make V=0 install DESTDIR=$SYSROOT
rm -rfv $SYSROOT/logs
check_success
#PATH=$CLFS/bin/:$PATH
cd ..
}

 CreateQemuImage()
 {

mkdir -p $SYSROOT/../x64image
cd $SYSROOT/../x64image
 rm -vf disk.img
 qemu-img create -f raw disk.img 1200M
 mkfs.ext4 -F disk.img
 mkdir fs
 sudo mount -o loop disk.img ./fs/
sudo cp -rfv $SYSROOT/* ./fs/
sudo cp -rfv $SYSROOT/boot/* ./
 sudo umount ./fs/
cd -
 #sudo qemu-system-x86_nvidia opensorce driver64 -kernel ./bzImage -initrd ./initramfs -serial stdio -append "root=/dev/ram0 console=ttyAMA0  console=ttyS0" -hda ./disk.img
 }

CLFS="$1"
SYSROOT="$CLFS/root"
HOST="x86_64-media-linux-gnu"
LINUX_VERSION=4.2
export PATH=$CLFS/bin/:$PATH
unset CFLAGS
unset CXXFLAGS

export CXX="x86_64-media-linux-gnu-g++"
export LD="x86_64-media-linux-gnu-ld"
export CC="x86_64-media-linux-gnu-gcc"
export AR="x86_64-media-linux-gnu-ar"
export RANLIB="x86_64-media-linux-gnu-ranlib"
export STRIP="x86_64-media-linux-gnu-strip"


#InstallBash

#InstallNcurses
#InstallHtop
#InstallNano

#InstallUtillinux
#CreatePkgShadow

#InstallCoreUtils
#InstallIproute2


#InstallReadline
#InstallGmp
#InstallNettle
#InstallGnutls
#InstallOpenConnect
#InstallIproute2
##InstallCurl
##InstallLibEvent
##InstallTransmission

#InstallLibAttr
#InstallLibCap
#InstallSystemD


#InstallZlib
#InstallOpenSSl
#InstallOpenSSH

#InstallPCRE
#InstallApr#
#InstallAprTool
#InstallApache


InstallLinux
#AddScratch
#InstallXbmc
#InstallInitram
#CreateQemuImage


