# Artifacts for PLDI25 Paper "Efficient Timestamping for Sampling-based Race Detection"

This artifact contains the experiment setup used for evaluating our work in improving the efficiency of data race detectors through the use of the sampling timestamp proposed in our paper.

In this experiment setup, LLVM is used to build MySQL with ThreadSanitizer, whose performance is then measured with [BenchBase](https://github.com/cmu-db/benchbase).
All of the necessary programs and scripts have been packaged in a Docker container, so that any researcher who is interested to reproduce or extend this work can easily do so.


## Get started

This section contains instructions for setting up the container and trying out a demo experiment.

### Setup Docker

First, [install Docker](https://docs.docker.com/get-started/get-docker/).
There are two ways of getting the Docker image.

#### Docker Hub

You may pull it from Docker Hub.

```sh
docker pull dwslim2/sampling-timestamp
```

#### Zenodo

Or you may download it from Zenodo, then load it with the following command.

```sh
docker load sampling-timestamp.tar.gz
```

### Open a shell in the Docker container

After pulling/loading the image, we can now start the container and open a shell to interact with it.

```sh
docker run -it sampling-timestamp bash
```

(You may need to run all the commands above with `sudo`.)


### Demo experiments

There are some small demo experiments under the `demo` directory.


#### Demo Experiment 1: Performance

```
cd /home/experiment/demos/experiment-1-performance
```

This experiment runs 2 different benchmarks, under 3 different MySQL builds, for 5 minutes each (inclusive of 1-minute warmup). (In total, this should take 2x3x5=30 minutes.)

We have chosen 2 benchmarks where our implementation has performed much better than the original TSan (modified to only process a sampled subset of events).
The 3 different MySQL builds are based on the ST, SU and SO configurations with 0.3% sampling rate, described in Section 6 of our paper.

To run the experiments, simply run the `run.sh` script.

```
./run.sh
```

For each run, the results are stored in the folder corresponding to that run.
For example, the performance results for `tatp` ran with the `ST-0.3%` configuration is stored under `tatp/st-03` in a JSON file whose name starts with the time of the run and ends with "summary.json".

To easily get the throughput results, you may run the following one-liner.

```
grep Throughput tatp/*/*summary.json
```

You might also be interested in other metrics such as the 75th percentile latency of the requests.

```
grep 75th tpch/*/*summary.json
```

For throughput, higher means faster, which means performs better. For latency, lower is better.
In accordance with our evaluation results in Section 6.2.2, the performance of SU and SO should be better than ST.

Note: Generally, the performance results should be reproducible on any computer, either a high-performance server or just a typical laptop.
Please see the [troubleshooting](#troubleshooting) section for more information if you cannot reproduce the results.


#### Demo Experiment 2: Number of data races

```
cd /home/experiment/demos/experiment-2-races
```

This experiment runs 1 benchmark, under 2 different MySQL builds, for 5 minutes each (inclusive of 1-minute warmup). (In total, this should take 1x2x5=10 minutes.)

Similar to above, the results for each run are stored in their corresponding folder.
The number of races reported is stored in a file whose name starts with the time of the run and ends with ".log".

For example, tatp/st-03/*.log will contain the number of data races that was detected by the ST-0.3% configuration.

To easily get the results, you may run the following one-liner.

```
grep warnings tatp/*/*.log
```

Note: This demo run is too short and will not be able to reproduce the results discussed in the paper.
This is because we are randomly sampling 0.3% of the read/write events, and it is only after running for a long time (e.g. 1 hour),
that when a huge number of events are encountered, will the number of data races detected be meaningful for comparison.


#### Demo Experiment 3: Profiling

```
cd /home/experiment/demos/experiment-3-profiling
```

This experiment runs 1 benchmark, under 2 different MySQL builds, for 5 minutes each (inclusive of 1-minute warmup). (In total, this should take 1x2x5=10 minutes.)
The experiment runs on the SU-prof-03 and SO-prof-03 builds, which sheds insight on the amount of work done/saved by our implementation as described in Section 6.2.3 of our paper.

Run them with `run.sh`.

```
./run.sh
```

Similar to above, the results for each run are stored in their corresponding folder.
The profiling results are stored in a file whose name starts with the time of the run and ends with ".log".

In the results, you can find counters such as number of locks or number of accesses encountered.
In the results for SU, you can also find the number of acquires encountered (`[UCLOCKS] Num original acquires`) and the number of acquires that our implementation needed to process (`[UCLOCKS] Num uclock acquires`). This lets us compute the ratio between amount of work "seen" vs amount of work "actually done". Under most benchmarks, our algorithm only needs to process around 50% of the acquires encountered.
Likewise, in the results for SO, you can also find the number of acquires encountered (`[OL] Num acquires`) and the number of linked-list traversals taken (`[OL] Num acquire ll traverses`). Under most benchmarks, only a small number of linked-list traversals is needed per acquire that is encountered.

Note: If the ratio of work done vs work encountered is too different from those discussed in the paper, that could be due to MySQL Server hitting its
saturation point, being too overloaded with requests.
Threads might spend a lot of time trying to acquire a lock but failing, or many threads do not make much progress while a single thread progresses a lot.
In both cases, the ratio will be affected because the frequency of synchronization between threads will be different; higher in the former, lower in the latter.
Please refer to the guide in the [troubleshooting](#troubleshooting) section for more information.


### Troubleshooting

#### Inconsistent results on a cluster

We have observed inconsistent performance when running the experiments on a HPC cluster.
We suspect that this is due to high variance in the response latency of the filesystem shared by a huge number of users,
which has a big impact on our experiments especially as a DBMS benchmark involves very frequent file I/O operations.

#### Noisy results due to high resource contention

If the experiment results that you obtain are too different from those discussed in the paper, that could be due to MySQL Server hitting its
saturation point, being too overloaded with requests.
When that happens, there will be high contention on system resources such as locks, CPU time, or IO resources, causing many threads to just spend time waiting instead of doing work.
To remedy this situation, you may reduce the number of terminals spawned by BenchBase. Please refer to the guide in the [Customize configuration section](#customize-configuration) to do so.

#### Terminating the experiment

If you stop the experiment by pressing Ctrl+C, the processes `mysqld` and `benchbase.jar` might not be terminated properly.
You can just enter `kill -9 $(pidof mysqld java)` to kill them before starting the next experiment.


## For advanced users

In this section, we elaborate on how one can try the experiments with different configurations (e.g. duration or number of terminals) or evaluate their own modifications to TSan in this setup.


### Customize configuration

To set up an experiment, first create a folder that will contain all the experiment files.
For example,

```
mkdir experiment
```

Then, create a config file `config.yaml` in that folder. You may copy the sample below and modify it accordingly.

```yaml
benchbase: /home/vagrant/benchbase
mysql: /home/vagrant/mysql/mysql-server-mysql-8.0.39
mysql-dist-no-tsan: dist-nt
workspace: /home/vagrant/benchbase-experiments/workspace
symbolizer: /home/vagrant/llvm-project/build/bin/llvm-symbolizer
seed: 1234
report-bugs: 0

duration: 3600
warmup: 120
terminals: 3

builds:
- nt
- t
- e
- st-03
- st-3
- st-10
- su-03
- su-3
- su-10
- so-03
- so-3
- so-10

warmup-run-duration: 60
warmup-run-mysql-build: nt

benchmarks:
- auctionmark
- epinions
- hyadapt
- noop
- resourcestresser
- seats
- sibench
- smallbank
- tatp
- tpcc
- tpch
- twitter
- voter
- wikipedia
- ycsb
```

The purposes of each of the fields above are as given below:
- `benchbase`: Path to BenchBase, as cloned from https://github.com/cmu-db/benchbase. It should already be built.
- `mysql`: Path to the MySQL folder where the built/installed files reside.
- `mysql-dist-no-tsan`: Path to the folder that contains MySQL built without TSan. This path is relative to the path in `mysql` above.
- `workspace`: Path to a folder for storing the MySQL database and other temporary files when the experiment is running. It should already exist.
- `symbolizer`: Path to the LLVM symbolizer.
- `duration`: Duration of each benchmarking run.
- `warmup`:  Duration for warmup before starting a benchmarking run.
- `terminals`: Number of terminals that BenchBase will use in a benchmarking run. It is mainly to control the concurrent load on the MySQL Server.
  - If it is too low, it exposes little concurrency, and experiments for algorithms that work well on concurrent benchmarks will see less prominent results.
  - If it is too high, the server will be overloaded, resulting in OS-level noise (that affects the evaluation of an algorithm) due to frequent context switching or waiting for other threads.
  - From experience, taking around 1/5 or 1/6 of the number of CPUs seem to work well.
- `builds`: List of MySQL builds that are to be benchmarked.
  - The corresponding builds should be stored in a folder with the name prefixed with "dist-".
  - For example, if `st-03` is in the list, `dist-st-03` must be present in the path denoted in `mysql`, and should be a MySQL install destination (according to `cmake --install <build folder> --prefix <install destination>`).
- `warmup-run-duration`: Duration for an extra run that occurs before the first run, in case one wants a longer warmup before the first run.
- `warmup-run-mysql-build`: MySQL build for that extra warmup run. Since the results should not matter, perhaps choose the fastest build so that it can achieve the best "warming up" effect.
- `benchmarks`: Benchmarks to run the experiment on. The available list of benchmarks are in the sample config above.

The available builds in this container are:
- `nt`: No TSan
- `t`: Unmodified TSan without race reporting
- `t-report`: Unmodified TSan with race reporting
- `e`: Empty. Does not handle any events (read/write/acquire/release) at all.
- `st-03`/`su-03`/`so-03`: ST/SU/SO with 0.3% sampling rate, **without profiling, without race reporting**
- `st-3`/`su-3`/`so-3`: ST/SU/SO with 3% sampling rate, **without profiling, without race reporting**
- `st-10`/`su-10`/`so-10`: ST/SU/SO with 10% sampling rate, **without profiling, without race reporting**
- `st-prof-03`/`su-prof-03`/`so-prof-03`: ST/SU/SO with 0.3% sampling rate, **with profiling**, without race reporting
- `st-prof-3`/`su-prof-3`/`so-prof-3`: ST/SU/SO with 3% sampling rate, **with profiling**, without race reporting
- `st-prof-10`/`su-prof-10`/`so-prof-10`: ST/SU/SO with 10% sampling rate, **with profiling**, without race reporting
- `st-report-03`/`su-report-03`/`so-report-03`: ST/SU/SO with 0.3% sampling rate, without profiling, **with race reporting**
- `st-report-3`/`su-report-3`/`so-report-3`: ST/SU/SO with 3% sampling rate, without profiling, **with race reporting**
- `st-report-10`/`su-report-10`/`so-report-10`: ST/SU/SO with 10% sampling rate, without profiling, **with race reporting**

Finally, use `setup-experiment` to generate all the experiment configuration files and scripts.

```
setup-experiment <path to experiment folder>
```


### Build your own MySQL

This subsection is for researchers who have modified TSan and want to compare their implementation against ours.

First, you need to switch to the `root` user to modify the programs. The password is `root`.

```sh
su - root
```

In this container, there is a helper script that rebuilds TSan after checking out a given git tag, and then relinks MySQL with the rebuilt TSan,
and installs it to a specified folder.
The script is located at `/usr/local/experiment/2-mysql/5-build-all.sh`.
It looks like the following. 

```sh
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

build sampling-timestamp-T dist-t
build sampling-timestamp-E dist-e
```

All you need to do is:
1. Tag your changes with `git tag` and push it to GitHub (can be to your own fork). For example,
  * https://github.com/focs-lab/llvm-project/tree/sampling-timestamp-SU-0.3
  * https://github.com/focs-lab/llvm-project/tree/sampling-timestamp-E
2. Make sure that the local llvm-project repository knows about your git tags. You will need to add your llvm-project fork as a remote:
  * `git remote add <pick a name> <url of your fork>`
3. Modify the script above to call `build <your tag> <where to install>`.
4. Run the script.


#### Example

For example, consider the scenario where I modified TSan with a new implementation and tagged it with `daniel-fast` in my fork of llvm-project at https://github.com/dwslim/llvm-project.
Below are the steps to build MySQL with it.

1. Switch to `root` user.
  * `su - root` (password is `root`)
2. Add my fork to the local llvm-project repository.
  * `cd /usr/local/experiment/llvm-project`
  * `git remote add daniel https://github.com/dwslim/llvm-project.git`
3. Modify the script:
  * `vim /usr/local/experiments/2-mysql/5-build-all.sh`
  * Remove the existing `build` commands.
  * Add `build daniel-fast dist-daniel-fast`.
4. Run the script.
  * `/usr/local/experiments/2-mysql/5-build-all.sh`


### Using the container like a virtual machine

In the guide above, we used `docker run` to start the container and open a shell to interact with it.
However, once the shell is closed, everything will be lost.

If you want the session to persist, you may start the container in detached mode.

```sh
docker run --detach -it --name experiment-box sampling-timestamp bash
```

You can run `docker ps` to see the running containers.

```sh
$ sudo docker ps
CONTAINER ID   IMAGE                COMMAND   CREATED          STATUS          PORTS     NAMES
da28c56dfea7   sampling-timestamp   "bash"    13 seconds ago   Up 12 seconds             experiment-box
```

Then, run `docker exec` to open a bash shell to interact with the container.

```sh
docker exec -it experiment-box bash
```

Notice that after closing the shell and opening a new one with `docker exec`, your changes persist.

Finally, run `docker stop` to stop the container if you are done with your experiments.

```sh
docker stop experiment-box
```

Note that even after stopping the container, you can still restart it with `docker start`, and your changes still persist!

```sh
docker start experiment-box
```

When you are finally done with the experiments and want to free up space, you may run `docker rm` to remove the container for good.

```sh
docker rm experiment-box
```


## Extending this setup for more experiments

If you would like to extend this Docker image with your own MySQL builds for further experiments, here are some pieces of useful information.

### Program locations

The experiment programs are stored in /usr/local/experiment, and can only be modified by the `root` user,
while a shell opened in the container will always run as the `experiment` user.
This prevents accidental modification of the program files.

The key locations are as follows, each of which are also stored in an environment variable:
- LLVM (`$LLVM`): /usr/local/experiment/llvm-project
- MySQL (`$MYSQL`): /usr/local/experiment/mysql-server-mysql-8.0.39
- BenchBase (`$BENCHBASE`): /usr/local/experiment/benchbase
- JDK (`$JAVA_HOME`): /usr/local/experiment/jdk-21
- Scripts used to build this Docker image: /usr/local/experiment/build-scripts

### Build

Generally, you might only need to build different versions of MySQL with your modified TSan implementations.
To do so, you can refer to the instructions in the [Build your own MySQL](#build-your-own-mysql) section.

To create your own Docker image with these changes, you can create a Dockerfile that looks like the following:

```
FROM dwslim2/sampling-timestamp:latest

USER root
WORKDIR /usr/local/experiment
# COPY your files.
# RUN commands to set up your experiments.

USER experiment
# Change the user back to `experiment` so that the container will open a shell as this user.
```

You may refer to the Dockerfile that was used to create this Docker image.

When the Dockerfile is ready, you can build it by running `docker build`.

```
docker build . -t your-tag-name
```

### Publish to Docker Hub

After building the image, you can push it to Docker Hub so that you or others do not need to build it again (like what I have done!).

First, you need to login to Docker Hub.

```
docker login
```

Then, you must tag your image with your username and your repository name on Docker Hub.
For example,

```
docker tag sampling-timestamp dwslim2/sampling-timestamp
```

Finally, you can push it to DockerHub.

```
docker push dwslim2/sampling-timestamp
```

If you get an error when pushing, you may need to run `docker login` with `sudo`.


### Save image to a tar archive

You might also want to save the image to a tar.gz archive, and then upload it to Zenodo.
You can do so with `docker save`.

```sh
docker save sampling-timestamp:latest | gzip > sampling-timestamp.tar.gz
```
