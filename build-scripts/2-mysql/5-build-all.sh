#!/bin/sh

build()
{
  TAG=$1
  NAME=$2

  # Rebuild TSan according to specified config.
  cd $LLVM
  git fetch --tags
  git clean -f .
  git checkout -f $TAG
  ninja -C build -j`nproc`

  # Relink MySQL with the changed compiler-rt library.
  cd $MYSQL
  rm build-t/bin/mysqld
  cmake --build build-t -j`nproc`
  cmake --install build-t --prefix $NAME
}

# Baselines
build sampling-timestamp-T dist-t
build sampling-timestamp-E dist-e

# For measuring throughputs
build sampling-timestamp-ST-0.3 dist-st-03
build sampling-timestamp-ST-3 dist-st-3
build sampling-timestamp-ST-10 dist-st-10

build sampling-timestamp-SU-0.3 dist-su-03
build sampling-timestamp-SU-3 dist-su-3
build sampling-timestamp-SU-10 dist-su-10

build sampling-timestamp-SO-0.3 dist-so-03
build sampling-timestamp-SO-3 dist-so-3
build sampling-timestamp-SO-10 dist-so-10

# For profiling work done
build sampling-timestamp-SU-prof-0.3 dist-su-prof-03
build sampling-timestamp-SU-prof-3 dist-su-prof-3
build sampling-timestamp-SU-prof-10 dist-su-prof-10

build sampling-timestamp-SO-prof-0.3 dist-so-prof-03
build sampling-timestamp-SO-prof-3 dist-so-prof-3
build sampling-timestamp-SO-prof-10 dist-so-prof-10

# For counting number of data races detected
build sampling-timestamp-ST-report-3 dist-st-report-3
build sampling-timestamp-SU-report-3 dist-su-report-3
build sampling-timestamp-SO-report-3 dist-so-report-3

build sampling-timestamp-ST-report-0.3 dist-st-report-03
build sampling-timestamp-SU-report-0.3 dist-su-report-03
build sampling-timestamp-SO-report-0.3 dist-so-report-03

build sampling-timestamp-ST-report-10 dist-st-report-10
build sampling-timestamp-SU-report-10 dist-su-report-10
build sampling-timestamp-SO-report-10 dist-so-report-10

build sampling-timestamp-T-report dist-t-report
