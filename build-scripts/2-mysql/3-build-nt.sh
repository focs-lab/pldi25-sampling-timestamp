#!/bin/sh

cd $MYSQL

export PATH=$(pwd)/downloads/usr/bin:$(pwd)/downloads/usr/local/bin:$PATH

cmake -S . -B build-nt -DCMAKE_INSTALL_PREFIX=dist-nt -DWITH_TSAN=OFF -DCMAKE_C_COMPILER=$LLVM/build/bin/clang -DCMAKE_CXX_COMPILER=$LLVM/build/bin/clang++ -DDOWNLOAD_BOOST=1 -DWITH_BOOST=downloads -DWITH_UNIT_TESTS=OFF -DINSTALL_MYSQLTESTDIR= -DCMAKE_PREFIX_PATH=$(pwd)/downloads/usr -DWITH_SSL=$(pwd)/downloads/usr -DHAVE_TERM_H=1 -DCMAKE_C_FLAGS="-I$(pwd)/downloads/usr/include -L$(pwd)/downloads/usr/lib -L$(pwd)/downloads/usr/lib64 -O1 -fno-inline" -DCMAKE_CXX_FLAGS="-I$(pwd)/downloads/usr/include -L$(pwd)/downloads/usr/lib -L$(pwd)/downloads/usr/lib64 -O1 -fno-inline"
cmake --build build-nt -j`nproc`
cmake --install build-nt


