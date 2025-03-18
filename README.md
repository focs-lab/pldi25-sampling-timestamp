# Artifacts for PLDI25 Paper "Efficient Timestamping for Sampling-based Race Detection"

This artifact contains the experiment setup used for evaluating our work in improving the efficiency of data race detection through the use of the sampling timestamp proposed in our paper.

In this experiment setup, LLVM is used to build MySQL with ThreadSanitizer, whose performance is then measured with [BenchBase](https://github.com/cmu-db/benchbase).
All of the necessary programs and scripts have been packaged in a Docker container, so that any researcher who is interested to reproduce or extend this work can easily do so.


## Get started

This section contains instructions for setting up the container and trying out a demo experiment.

### Setup Docker

First, [install Docker](https://docs.docker.com/get-started/get-docker/).

Then, load and run the Docker image with a shell open.

```sh
docker load sampling-timestamp.tar.gz
docker run sampling-timestamp -it bash
```

(You may need to run the commands above with `sudo`.)

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


#### Demo Experiment 2: Number of data races

```
cd /home/experiment/demos/experiment-2-races
```

This experiment runs 1 benchmark, under 2 different MySQL builds, for 5 minutes each (inclusive of 1-minute warmup). (In total, this should take 1x2x5=10 minutes.)

Similar to above, the results for each run are stored in their corresponding folder.
The number of races reported is stored in a file whose name starts with the time of the run and ends with ".log".

For example, tatp/st-03/*.log will contain the number of data races that was detected by the ST-0.3% configuration.


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
In the results for SU, you can also find the number of acquires encountered (`[UCLOCKS] Num original acquires`) and the number of acquires that our implementation needed to process (`[UCLOCKS] Num uclock acquires`). This lets us compute the ratio between amount of work "seen" vs amount of work "actually done". Notice that our algorithm only needed to process around 50% of the acquires encountered.
Likewise, in the results for SO, you can also find the number of acquires encountered (`[OL] Num acquires`) and the number of linked-list traversals taken (`[OL] Num acquire ll traverses`). Notice that only a small number of linked-list traversals is needed per acquire that is encountered.


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

Finally, use `setup-experiment` to generate all the experiment configuration files and scripts.

```
setup-experiment <path to experiment folder>
```
