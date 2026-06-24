#!/bin/bash --login
#SBATCH --begin=now
#SBATCH --time=6:00:00
#SBATCH --partition=a100
#SBATCH --job-name=Tuner
#SBATCH --mem=50G
#SBATCH -A usp-2024.1


GPUCOUNT=$SLURM_NTASKS


if [ -z "$GPUCOUNT" ] || [ "$GPUCOUNT" -eq 0 ]; then
    echo "Error: GPUCOUNT is not set or is 0" >&2
    exit 1
fi

module load  nvhpc-hpcx-2.20-cuda12/26.3
conda activate devitopro311

#export PYTHONPATH=/home/andre.farinha/paper_multigpu/bench_multigpu/devitopro-trial-avenir

export BENCHMARK_SCRIPT=minimal_acoustic.py

devito_lang=cuda
devito_arch=cuda

domain_sizes=(256 512 1024)
space_orders=(2 4 8)



# for every space order
for space_order_idx in "${!space_orders[@]}"
    do
        SPACE_ORDER=${space_orders[$space_order_idx]}
    # for every domain size
    for domain_size in "${domain_sizes[@]}"
    do
        DOMAIN_SIZE=$domain_size
        # adjust for the issue with large domains
        if [ $DOMAIN_SIZE -eq 1024 ]
        then
            FIXED_OPT="('fixed', {'index-mode': 'int64'})"

        # organize the execution command based on the number of GPUs
        fi
        if [ "$GPUCOUNT" -eq 1 ]
        then
            DEVITO_MPI=0
            EXEC_CMD="python3 -m devitotuner "
        else
            DEVITO_MPI="diag2"
            EXEC_CMD="mpirun -np $GPUCOUNT python3 -m devitotuner "
        fi
    # now the repetitions
        echo "= START ="
        echo "TUNING WITH"
        echo "devito-version: pro"

        echo "gpu-num: $GPUCOUNT"
        echo "domain-size: $DOMAIN_SIZE"
        echo "space-order: $SPACE_ORDER"
        echo "mpi: $DEVITO_MPI"

        
        export DEVITO_LANGUAGE=$devito_lang 
        export DEVITO_PLATFORM="nvidiaX" 
        export DEVITO_ARCH=$devito_arch 
        export DEVITO_MPI=$DEVITO_MPI 
        export DEVITO_LOGGING=DEBUG 
        export DEVITO_TUNER_VERBOSE=0

        

        # include FIXED_OPT only if set
        if [ -n "$FIXED_OPT" ]; then
            echo "Using FIXED_OPT: $FIXED_OPT"
            $EXEC_CMD Simple A100_cimatec/A100_so_${SPACE_ORDER}_d_${DOMAIN_SIZE}_gpu_${GPUCOUNT}.json "$FIXED_OPT" $BENCHMARK_SCRIPT \
            -d $DOMAIN_SIZE $DOMAIN_SIZE $DOMAIN_SIZE \
            -so $SPACE_ORDER \
            -tn 100 \
            -ngpus $GPUCOUNT
        else

            $EXEC_CMD Simple A100_cimatec/A100_so_${SPACE_ORDER}_d_${DOMAIN_SIZE}_gpu_${GPUCOUNT}.json $BENCHMARK_SCRIPT \
            -d $DOMAIN_SIZE $DOMAIN_SIZE $DOMAIN_SIZE \
            -so $SPACE_ORDER \
            -tn 100 \
            -ngpus $GPUCOUNT
        fi

        
        echo "= END ="
    done
done
