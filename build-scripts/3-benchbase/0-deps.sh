#!/bin/sh

wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.6%2B7/OpenJDK21U-jdk_x64_linux_hotspot_21.0.6_7.tar.gz
tar -xzvf OpenJDK21U-jdk_x64_linux_hotspot_21.0.6_7.tar.gz
mv jdk-21.0.6+7 jdk-21
