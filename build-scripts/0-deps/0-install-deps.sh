#!/bin/sh

apt update
apt install -y git
apt install -y binutils-dev ccache clang cmake ninja-build libstdc++-12-dev
apt install -y build-essential make m4
