#!/bin/sh
#sudo apt-get g++ libncurses5-dev libtinfo-dev g++-4.9 autopoint libapr1 libaprutil1 libserf-1-1 libsvn1 subversion gcc gcc-4.9 libtool gperf libgcrypt-dev intltool gettext automake autogen autoconf autogen autogen-doc automake autotools-dev guile-2.0-libs libgc1c2 libopts25 libopts25-dev m4
# fonts-lmodern fonts-texgyre libfile-homedir-perl libfile-which-perl
#  libjs-jquery libpotrace0 libptexenc1 libruby2.1 libsynctex1 libyaml-0-2
#  libzzip-0-13 lmodern prosper ps2eps ruby ruby2.1 rubygems-integration
#  tex-common tex-gyre texlive texlive-base texlive-binaries
#  texlive-extra-utils texlive-font-utils texlive-fonts-recommended
#  texlive-fonts-recommended-doc texlive-generic-recommended texlive-latex-base
#  texlive-latex-base-doc texlive-latex-recommended
#  texlive-latex-recommended-doc texlive-pictures texliv e-pictures-doc
#  texlive-pstricks texlive-pstricks-doc tipa bison libprotobuf-c-dev libprotobuf-c1 libprotoc9 protobuf-c-compiler flex libfl-dev gnutls-bin

TARGET="x86_64-media-linux-gnu"
CLFS="$1"
isget="$2"
SYSROOT="$CLFS/root"
export PATH=$CLFS/bin/:$PATH
HOST="x86_64-pc-linux-gnu"
LINUX_VERSION=4.2
BINUTILS_VERSION=2.25
GCC_VERSION=5.2.0
unset CFLAGS
unset CXXFLAGS
check_success() {
   if [ $? -ne 0 ]
   then
      echo Failed
      exit 1
   fi
   echo Done
}

if [ "$2" = "clear" ]
then
    rm -rfv $CLFS
    mkdir -p $SYSROOT
    check_success
exit 1
fi
mkdir -p $SYSROOT



InstallKernelHeader()
{

if [ "$isget" = "get" ]
then
    wget -c "https://www.kernel.org/pub/linux/kernel/v4.x/linux-$LINUX_VERSION.tar.gz"
    tar -xf linux-$LINUX_VERSION.tar.gz
    rm linux-$LINUX_VERSION.tar.gz
fi
echo -n "Install kernel headers..."
cd linux-$LINUX_VERSION/
if [ "$isget" != "install" ]
then
    make mrproper
    make ARCH=x86 headers_check
fi
make ARCH=x86 INSTALL_HDR_PATH=$SYSROOT headers_install
cd -
check_success
}

InstallBinutils()
{

if [ "$isget" = "get" ]
then
    wget -c "http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz"
    tar -xf binutils-$BINUTILS_VERSION.tar.gz
    rm binutils-$BINUTILS_VERSION.tar.gz
fi
echo -n "Install binutils..."
mkdir $TARGET-binutils
cd $TARGET-binutils
if [ "$isget" != "install" ]
then
    rm -rf ./*
    ../binutils-$BINUTILS_VERSION/configure --prefix=$CLFS --target=$TARGET --with-sysroot=$SYSROOT  --disable-nls --enable-plugins
    make V=0 -j 9 
check_success
fi
make install
check_success
cd ..

}

InstallStaticGCC()
{
if [ "$isget" = "get" ]
then
    wget -c "http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.bz2"
    tar -xf gcc-$GCC_VERSION.tar.bz2
    rm /gcc-$GCC_VERSION.tar.bz2
    cd ./gcc-$GCC_VERSION/
    ./contrib/download_prerequisites
    cd ..
    check_success

fi
echo -n "Install static gcc..."
mkdir $TARGET-static-gcc
cd $TARGET-static-gcc
if [ "$isget" != "install" ]
then
    rm -rf ./*
    ../gcc-$GCC_VERSION/configure --disable-multilib --target=$TARGET --prefix=$CLFS --with-sysroot=$SYSROOT --disable-nls  --disable-shared --without-headers --with-newlib --disable-decimal-float --disable-libgomp --disable-libmudflap --disable-libssp --disable-threads --disable-libatomic --disable-libitm --disable-libsanitizer --disable-libquadmath --disable-target-libiberty --enable-languages=c --enable-checking=release
    make V=0 all-gcc -j 9 
    check_success
    make V=0 all-target-libgcc -j 9 
    check_success 
fi
make install-gcc install-target-libgcc
check_success
cd ..
}


InstallEGLIB()
{
if [ "$isget" = "get" ]
then
    svn co http://www.eglibc.org/svn/trunk eglibc
fi

echo -n "Install eglibs header files..."
mkdir $TARGET-eglibs
cd $TARGET-eglibs
if [ "$isget" != "install" ]
then
    rm -rf ./*
    echo "libc_cv_ssp=no" > config.cache
    BUILD_CC="gcc" \
    CC="$CLFS/bin/$TARGET-gcc" \
    AR="$CLFS/bin/$TARGET-ar" \
    RANLIB="$CLFS/bin/$TARGET-ranlib" \
    ../eglibc/libc/configure \
    --prefix=/ \
    --with-headers=$SYSROOT/include \
    --build=$HOST \
    --host=$TARGET \
    --disable-profile --without-gd --without-cvs --enable-add-ons --cache-file=config.cache
    check_success
    make V=0 -j 9
    check_success
fi
make install install_root=$SYSROOT
check_success
cd ..
}

InstallGLIB()
{
if [ "$isget" = "get" ]
then
    git clone git://sourceware.org/git/glibc.git
fi

echo -n "Install eglibs header files..."
mkdir $TARGET-glibc
cd $TARGET-glibc
if [ "$isget" != "install" ]
then
    rm -rf ./*
    echo "libc_cv_ssp=no" > config.cache
    BUILD_CC="gcc" \
    CC="$CLFS/bin/$TARGET-gcc" \
    AR="$CLFS/bin/$TARGET-ar" \
    RANLIB="$CLFS/bin/$TARGET-ranlib" \
    ../glibc/configure \
    --prefix=/ \
    --with-headers=$SYSROOT/include \
    --build=$HOST \
    --host=$TARGET \
    --enable-obsolete-rpc \
    --disable-profile --without-gd --without-cvs --enable-add-ons --cache-file=config.cache
    check_success 
    make V=0 -j 9
    check_success
fi
make install install_root=$SYSROOT
check_success
cd ..
}

InstallFinallGCC()
{
if [ "$isget" = "get" ]
then
    wget -c "http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.bz2"
    tar -xf gcc-$GCC_VERSION.tar.bz2
    rm /gcc-$GCC_VERSION.tar.bz2
    cd ./gcc-$GCC_VERSION/
    ./contrib/download_prerequisites
    cd ..
    check_success

fi
echo -n "Install final gcc..."
mkdir $TARGET-final-gcc
cd $TARGET-final-gcc
if [ "$isget" != "install" ]
then
    rm -rf ./*
    ../gcc-$GCC_VERSION/configure \
    --build=$HOST --target=$TARGET --host=$HOST --prefix=$CLFS \
    --with-sysroot=$SYSROOT --enable-shared --enable-languages=c,c++ \
    --with-native-system-header-dir=/include \
    --enable-__cxa_atexit --enable-c99 --enable-long-long --enable-threads=posix \
    --enable-checking=release \
    --disable-multilib \
    --disable-nls \
    --disable-libstdcxx-pch \
    --disable-multilib     \
    --disable-bootstrap \
    --disable-libgomp
    make V=0 AS_FOR_TARGET="$TARGET-as" LD_FOR_TARGET="$TARGET-ld" -j 9 
    check_success
fi
make install
mkdir -p $SYSROOT/lib
cp -fv $CLFS/x86_64-media-linux-gnu/lib64/libgcc* $SYSROOT/lib 
check_success
cd ..
}
 
#InstallKernelHeader
#InstallBinutils
#InstallStaticGCC
InstallGLIB
InstallFinallGCC
