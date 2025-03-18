#!/bin/sh

cd $BENCHBASE
./mvnw clean package -P mysql -Dmaven.test.skip=true

cd target
tar -xzvf benchbase-mysql.tgz
