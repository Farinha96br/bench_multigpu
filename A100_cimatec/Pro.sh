#!/bin/bash --login
#SBATCH --begin=now
#SBATCH --time=0-12:00:00
#SBATCH --partition=a100
#SBATCH --job-name=Pro
#SBATCH --cpus-per-task=4
#SBATCH --mem=50G
#SBATCH -A usp-2024.1


GPUCOUNT=$SLURM_NTASKS


if [ -z "$GPUCOUNT" ] || [ "$GPUCOUNT" -eq 0 ]; then
    echo "Error: GPUCOUNT is not set or is 0" >&2
    exit 1
fi

module load  nvhpc-hpcx-2.20-cuda12/26.3

conda activate devitopro311
export BENCHMARK_SCRIPT=minimal_acoustic.py

devito_lang=cuda
devito_arch=cuda
devito_platform=nvidiaX


domain_sizes=(256 512 1024)
space_orders=(2 4 8 2 4 8)
final_times=(400 400 400 4000 4000 4000) 
repeats=5


for space_order_idx in "${!space_orders[@]}"
    do
        SPACE_ORDER=${space_orders[$space_order_idx]}
        FINAL_TIME=${final_times[$space_order_idx]}
    for domain_size in "${domain_sizes[@]}"
    do
        DOMAIN_SIZE=$domain_size
        if [ $GPUCOUNT -eq 1 ]
        then
            DEVITO_MPI=0
            EXEC_CMD="python3 "
        else
            DEVITO_MPI=diag2
            EXEC_CMD="mpirun -np $GPUCOUNT python3 "
        fi
        # now the repetitions

        for j in $(seq 1 $repeats)
        do
            echo "= START ="
            echo "run-number: $j"
            echo "domain-size: $DOMAIN_SIZE"
            echo "space-order: $SPACE_ORDER"
            echo "time-steps: $FINAL_TIME" 
            echo "devito-version: Pro"
            echo "gpu-num: $GPUCOUNT"
            echo "mpi: $DEVITO_MPI"

            
            export DEVITO_LANGUAGE=$devito_lang 
            export DEVITO_PLATFORM=nvidiaX 
            export DEVITO_ARCH=$devito_arch 
            export DEVITO_LOGGING=DEBUG 
            export DEVITO_MPI=$DEVITO_MPI 
            $EXEC_CMD $BENCHMARK_SCRIPT \
            -d $DOMAIN_SIZE $DOMAIN_SIZE $DOMAIN_SIZE \
            -so $SPACE_ORDER \
            -tn $FINAL_TIME \
            -pro True \
            -machine A100_cimatec \
            -gpumodel A100 \
            -ngpus $GPUCOUNT

            echo "= END ="
                
        done
    done
done

echo "All runs completed."
