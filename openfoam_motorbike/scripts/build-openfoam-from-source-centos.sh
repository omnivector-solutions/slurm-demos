#!/bin/bash

### Install dependencies
yum makecache
yum install -y centos-release-scl
yum install -y devtoolset-9    
yum install -y wget git openssl-devel libuuid-devel python3 flex bzip2
yum install -y boost-devel gnuplot libXt-devel mesa-libGL-devel ncurses-devel qt4-devel qtwebkit-devel readline-devel zlib-devel

### Update environment - GCC 9 and other tools
### This is required to build GCC 5.5.0
source /opt/rh/devtoolset-9/enable

### Go to HOME directory
cd $HOME

### Build gcc 5.5.0
### Somehow OpenFOAM v10 only works good in centos 7 when built with GCC 5.5.0
wget https://bigsearcher.com/mirrors/gcc/releases/gcc-5.5.0/gcc-5.5.0.tar.gz --no-check-certificate
tar -xzvf gcc-5.5.0.tar.gz
cd gcc-5.5.0
./contrib/download_prerequisites
cd ..
mkdir gcc-build
cd gcc-build
../gcc-5.5.0/configure --prefix=/opt/gcc-5.5.0 --enable-shared --enable-threads=posix --enable-__cxa_atexit --enable-clocale=gnu  --enable-languages=all --disable-multilib
make -j 4
make install

### Update environment - GCC 5.5.0
export PATH=/opt/gcc-5.5.0/bin:$PATH 
export LD_LIBRARY_PATH=/opt/gcc-5.5.0/lib:/opt/gcc-5.5.0/lib64:$LD_LIBRARY_PATH

### Go to HOME directory
cd $HOME

### Install MPICH   
wget https://www.mpich.org/static/downloads/3.2/mpich-3.2.tar.gz
tar xf mpich-3.2.tar.gz && rm -f mpich-3.2.tar.gz
cd mpich-3.2
./configure --prefix=/opt/mpich
make -j 4
make install

### Update environment - MPICH
export MPI_DIR=/opt/mpich
export MPI_BIN=$MPI_DIR/bin
export MPI_LIB=$MPI_DIR/lib
export MPI_INC=$MPI_DIR/include
export PATH=$MPI_BIN:$PATH
export LD_LIBRARY_PATH=$MPI_LIB:$LD_LIBRARY_PATH

### Go to HOME directory
cd $HOME

### These files and folders are no longer needed
rm -rf gcc-5.5.0 gcc-5.5.0.tar.gz gcc-build mpich-3.2

### Create a base directory for OpenFOAM installation
mkdir -p /opt/OpenFOAM

### Download and extract OpenFOAM v10
wget -O - http://dl.openfoam.org/source/10 | tar xvz
wget -O - http://dl.openfoam.org/third-party/10 | tar xvz

### Move OpenFOAM to the base directory
mv OpenFOAM-10-version-10 /opt/OpenFOAM/OpenFOAM-10
mv ThirdParty-10-version-10 /opt/OpenFOAM/ThirdParty-10

### Set OpenFOAM base directory
sed -i 's/FOAM_INST_DIR=$HOME\/$WM_PROJECT/FOAM_INST_DIR=\/opt\/$WM_PROJECT/g' /opt/OpenFOAM/OpenFOAM-10/etc/bashrc

### Config MPICH as the MPI used by OpenFOAM
sed -i 's/export WM_MPLIB=SYSTEMOPENMPI/export WM_MPLIB=SYSTEMMPI/g' /opt/OpenFOAM/OpenFOAM-10/etc/bashrc
export WM_MPLIB=SYSTEMMPI
export MPI_ROOT=/opt/mpich
export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"
export MPI_ARCH_INC="-I${MPI_ROOT}/include"
export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib -lmpich"

### Source OpenFOAM bashrc file
source /opt/OpenFOAM/OpenFOAM-10/etc/bashrc

### Build ThirdParty tools
cd /opt/OpenFOAM/ThirdParty-10
./Allwmake

### Remove unnecessary files
rm -rf build gcc-* gmp-* mpfr-* binutils-* boost* ParaView-* qt-*

### Build OpenFOAM v10
cd /opt/OpenFOAM/OpenFOAM-10
./Allwmake

### Update /etc/bashrc to set environment variables when starting the system
echo "export PATH=/opt/gcc-5.5.0/bin:\$PATH" >> /etc/bashrc
echo "export LD_LIBRARY_PATH=/opt/gcc-5.5.0/lib:/opt/gcc-5.5.0/lib64:\$LD_LIBRARY_PATH" >> /etc/bashrc

echo "export MPI_DIR=/opt/mpich" >> /etc/bashrc
echo "export MPI_BIN=\$MPI_DIR/bin" >> /etc/bashrc
echo "export MPI_LIB=\$MPI_DIR/lib" >> /etc/bashrc
echo "export MPI_INC=\$MPI_DIR/include" >> /etc/bashrc
echo "export PATH=\$MPI_BIN:\$PATH" >> /etc/bashrc
echo "export LD_LIBRARY_PATH=\$MPI_LIB:\$LD_LIBRARY_PATH" >> /etc/bashrc

echo "export WM_MPLIB=SYSTEMMPI" >> /etc/bashrc
echo "export MPI_ROOT=/opt/mpich" >> /etc/bashrc
echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"' >> /etc/bashrc
echo 'export MPI_ARCH_INC="-I\${MPI_ROOT}/include"' >> /etc/bashrc
echo 'export MPI_ARCH_LIBS="-L\${MPI_ROOT}/lib -lmpich"' >> /etc/bashrc

echo "source /opt/OpenFOAM/OpenFOAM-10/etc/bashrc" >> /etc/bashrc


 
