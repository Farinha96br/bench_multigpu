# This is the repository to execute the benchmarks and tunning for the paper "multi GPU"

The goal of this routine is:
- For each machine: Download the devito repository
- Modify the utils.py so that the aquisition has a single receptor
- Execute an array of paramerers using the open version of devito
- Tune the same arry of parameter using devitoPRO
- execute the benchmark using the tuned parameters
- extract the runtimes (And possible other metrics)

the file ´´´tuned_params.json´´´ has all the tunned paramers, per machine per run configuration (SO, domain size, and GPU number)

## Job array:






