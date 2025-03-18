#!/bin/sh

cd $LLVM
git checkout sampling-timestamp-configs
cmake -S llvm -B build -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="clang" -DLLVM_ENABLE_RUNTIMES="compiler-rt;openmp;libcxx;libcxxabi;libunwind" -DLIBOMP_OMPT_SUPPORT=ON -DBUILD_SHARED_LIBS=ON -DLLVM_BINUTILS_INCDIR=/usr/include -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DLLVM_TARGETS_TO_BUILD=X86
ninja -C build -j`nproc`
