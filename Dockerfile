FROM ubuntu:24.04

WORKDIR /usr/local/experiment
ENV WORKDIR=/usr/local/experiment

COPY build-scripts/0-deps ./0-deps
RUN 0-deps/0-install-deps.sh

COPY build-scripts/1-tsan ./1-tsan
ENV LLVM=$WORKDIR/llvm-project
RUN 1-tsan/1-fetch.sh
RUN 1-tsan/2-build.sh

COPY build-scripts/2-mysql ./2-mysql
ENV MYSQL=$WORKDIR/mysql-server-mysql-8.0.39
RUN 2-mysql/0-deps.sh
RUN 2-mysql/1-fetch.sh
RUN 2-mysql/2-deps.sh
RUN 2-mysql/3-build-nt.sh
RUN 2-mysql/4-build-t.sh
RUN 2-mysql/5-build-all.sh

COPY build-scripts/3-benchbase ./3-benchbase
ENV JAVA_HOME=$WORKDIR/jdk-21
ENV BENCHBASE=$WORKDIR/benchbase
RUN 3-benchbase/0-deps.sh
RUN 3-benchbase/1-fetch.sh
RUN 3-benchbase/2-patch.sh
RUN 3-benchbase/3-build.sh

COPY build-scripts/4-experiment ./4-experiment
RUN 4-experiment/0-deps.sh
RUN 4-experiment/1-fetch.sh

COPY build-scripts/5-demos ./5-demos
RUN 5-demos/0-deps.sh
RUN 5-demos/1-setup.sh

ENV WORKDIR=

RUN chown -R experiment:experiment /home/experiment/demos

USER experiment
WORKDIR /home/experiment
