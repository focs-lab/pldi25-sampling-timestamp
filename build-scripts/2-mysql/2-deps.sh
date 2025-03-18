#!/bin/sh

cd $MYSQL

mkdir downloads
cd downloads
mkdir usr

# Bison
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xzvf bison-3.8.2.tar.gz
cd bison-3.8.2
./configure --prefix=$(pwd)/../usr
make -j`nproc`
make install
cd ..

# OpenSSl
wget https://github.com/openssl/openssl/releases/download/openssl-3.0.13/openssl-3.0.13.tar.gz
tar -xzvf openssl-3.0.13.tar.gz
cd openssl-3.0.13
./Configure --prefix=$(pwd)/../usr
make -j`nproc`
make install
cd ..

# libtirpc
wget -O libtirpc-1.3.5.tar.bz2 https://sourceforge.net/projects/libtirpc/files/libtirpc/1.3.5/libtirpc-1.3.5.tar.bz2/download
tar -xf libtirpc-1.3.5.tar.bz2
cd libtirpc-1.3.5
./configure --prefix=$(pwd)/../usr --disable-gssapi 
make -j`nproc`
make install
cd ..

# patchelf
wget https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0.tar.gz
tar -xzvf patchelf-0.18.0.tar.gz
cd patchelf-0.18.0
./configure --prefix=$(pwd)/../usr
make -j`nproc`
make install
cd ..

# ncurses
wget https://ftp.gnu.org/gnu/ncurses/ncurses-6.3.tar.gz
tar -xzvf ncurses-6.3.tar.gz
cd ncurses-6.3
./configure --prefix=$(pwd)/../usr
make -j`nproc`
make install
cd ..
