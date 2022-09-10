#!/bin/bash

### Install dependencies
apt update && apt upgrade -y
apt install -y wget build-essential cmake git ca-certificates flex libfl-dev gfortran bison zlib1g-dev libboost-system-dev libboost-thread-dev gnuplot 
apt install -y libreadline-dev libncurses-dev libxt-dev libqt5x11extras5-dev libxt-dev qt5-default qttools5-dev curl

### Update environment - GCC 9 and other tools
source /opt/rh/devtoolset-9/enable

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
rm -rf mpich-3.2

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

### Update ~/.bashrc to set environment variables when starting the system
echo "source /opt/rh/devtoolset-9/enable" >> ~/.bashrc

echo "export MPI_DIR=/opt/mpich" >> ~/.bashrc
echo "export MPI_BIN=\$MPI_DIR/bin" >> ~/.bashrc
echo "export MPI_LIB=\$MPI_DIR/lib" >> ~/.bashrc
echo "export MPI_INC=\$MPI_DIR/include" >> ~/.bashrc
echo "export PATH=\$MPI_BIN:\$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$MPI_LIB:\$LD_LIBRARY_PATH" >> ~/.bashrc

echo "export WM_MPLIB=SYSTEMMPI" >> ~/.bashrc
echo "export MPI_ROOT=/opt/mpich" >> ~/.bashrc
echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"' >> ~/.bashrc
echo 'export MPI_ARCH_INC="-I\${MPI_ROOT}/include"' >> ~/.bashrc
echo 'export MPI_ARCH_LIBS="-L\${MPI_ROOT}/lib -lmpich"' >> ~/.bashrc

echo "source /opt/OpenFOAM/OpenFOAM-10/etc/bashrc" >> ~/.bashrc


 
