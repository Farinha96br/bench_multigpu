# This is the repository to execute the benchmarks and tunning for the paper "multi GPU"

The goal of this routine is:
- For each machine: Download the devito repository
- Modify the utils.py so that the aquisition has a single receptor
- Execute an array of paramerers using the open version of devito
- Tune the same arry of parameter using devitoPRO
- execute the benchmark using the tuned parameters
- extract the runtimes (And possible other metrics)

the file ´´´tuned_params.json´´´ has all the tunned paramers, per machine per run configuration (SO, domain size, and GPU number)

## Nomenclature

The file and naming formatting for the tunning `.json` output will, always be:

`<machine>\<GPUmodel>_so_<so>_d_<domain_size/shape>_gpu_<gpucount>.json`

example:

`dgx_h200/h200_so_2_d_256_gpu_1.json`







