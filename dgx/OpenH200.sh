#!/bin/bash
#SBATCH --begin=now
#SBATCH --time=0-12:00:00
#SBATCH --partition=large
#SBATCH --job-name=open
#SBATCH --cpus-per-task=4
#SBATCH --mem=50G

if [ -z "$SLURM_GPUS_ON_NODE" ] || [ "$SLURM_GPUS_ON_NODE" -eq 0 ]; then
    echo "Error: SLURM_GPUS_ON_NODE is not set or is 0" >&2
    exit 1
fi

module load apptainer 

export IMAGE_PATH=/home/afarinha_local/devito_nvidia-nvc12-dev-amd64.sif
export APPTAINER_TMPDIR=/home/afarinha_local/apptainertmpdir
export APPTAINER_CACHEDIR=/home/afarinha_local/apptainercachedir
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

export BENCHMARK_SCRIPT=minimal_acoustic.py

devito_lang=openacc
devito_arch=nvc
devito_platform=nvidiaX


domain_sizes=(1024)
space_orders=(2 4 8)
final_times=(400 400 400) 
repeats=5



for space_order_idx in "${!space_orders[@]}"
    do
        SPACE_ORDER=${space_orders[$space_order_idx]}
        FINAL_TIME=${final_times[$space_order_idx]}
    for domain_size in "${domain_sizes[@]}"
    do
        DOMAIN_SIZE=$domain_size
        if [ $SLURM_GPUS_ON_NODE -eq 1 ]
        then
            DEVITO_MPI=0
        else
            DEVITO_MPI=basic
        fi
        # now the repetitions
        for j in $(seq 1 $repeats)
        do
            echo "= START ="
            echo "run-number: $j"
            echo "domain-size: $DOMAIN_SIZE"
            echo "space-order: $SPACE_ORDER"
            echo "time-steps: $FINAL_TIME" 
            echo "devito-version: open"
            echo "gpu-num: $SLURM_GPUS_ON_NODE"
            echo "mpi: $DEVITO_MPI"

            apptainer exec --nv ${IMAGE_PATH} bash -c \
            "export DEVITO_LANGUAGE=$devito_lang && \
            export DEVITO_PLATFORM=nvidiaX && \
            export DEVITO_ARCH=$devito_arch && \
            source /venv/bin/activate && \
            export PYTHONPATH=devito/ && \
            export DEVITO_LOGGING=DEBUG && \
            export DEVITO_MPI=$DEVITO_MPI && \
            mpirun -np $SLURM_GPUS_ON_NODE python3 $BENCHMARK_SCRIPT \
            -d $DOMAIN_SIZE $DOMAIN_SIZE $DOMAIN_SIZE \
            -so $SPACE_ORDER \
            -tn $FINAL_TIME"

            echo "= END ="
                
        done
    done
done

echo "All runs completed."
