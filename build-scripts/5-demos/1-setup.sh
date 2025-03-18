#!/bin/bash

ln -s $WORKDIR/benchbase-experiments/setup_experiment.py $WORKDIR/benchbase-experiments/setup-experiment
chmod +x $WORKDIR/benchbase-experiments/setup-experiment

useradd -m experiment

echo "export PATH=$WORKDIR/benchbase-experiments:\$PATH" >> /home/experiment/.bashrc
echo "export PATH=$WORKDIR/jdk-21/bin:\$PATH" >> /home/experiment/.bashrc
echo "export JAVA_HOME=$WORKDIR/jdk-21" >> /home/experiment/.bashrc

export PATH=$WORKDIR/benchbase-experiments:$PATH

cd /home/experiment
mkdir demos
cp -r $WORKDIR/4-experiment/experiment-1-performance demos
cp -r $WORKDIR/4-experiment/experiment-2-races demos
cp -r $WORKDIR/4-experiment/experiment-3-profiling demos
setup-experiment demos/experiment-1-performance
setup-experiment demos/experiment-2-races
setup-experiment demos/experiment-3-profiling
chown -R experiment:experiment /home/experiment/demos

mkdir /tmp/workspace
chown -R experiment:experiment /tmp/workspace
