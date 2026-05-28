#!/bin/bash
#SBATCH --begin=now
#SBATCH --time=0-12:00:00
#SBATCH --partition=gpulongc
#SBATCH --job-name=tunerV200
#SBATCH --cpus-per-task=4
#SBATCH --mem=50G


if [ -n "$SLURM_GPUS_ON_NODE" ]; then
    GPUCOUNT=$SLURM_GPUS_ON_NODE
else
    GPUCOUNT=$SLURM_NTASKS
fi

if [ -z "$GPUCOUNT" ] || [ "$GPUCOUNT" -eq 0 ]; then
    echo "Error: GPUCOUNT is not set or is 0" >&2
    exit 1
fi

export IMAGE_PATH=/home/cimatec/andre.farinha/devito_nvidia-nvc12-dev-amd64.sif
export APPTAINER_TMPDIR=/home/cimatec/andre.farinha/apptainertmpdir
export APPTAINER_CACHEDIR=/home/cimatec/andre.farinha/apptainercachedir
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

export BENCHMARK_SCRIPT=minimal_acoustic.py

devito_lang=cuda
devito_arch=cuda
devito_platform=nvidiaX

domain_sizes=(256 512 1024)
space_orders=(2 4 8)
final_times=(500) 

for space_order_idx in "${!space_orders[@]}"
    do
        SPACE_ORDER=${space_orders[$space_order_idx]}
    for domain_size in "${domain_sizes[@]}"
    do
        DOMAIN_SIZE=$domain_size
        if [ $SLURM_GPUS_ON_NODE -eq 1 ]
        then
            DEVITO_MPI=0
        else
            DEVITO_MPI="diag2"
        fi
    # now the repetitions
        echo "= START ="
        echo "TUNING WITH"
        echo "devito-version: pro"

        echo "gpu-num: $GPUCOUNT"
        echo "domain-size: $DOMAIN_SIZE"
        echo "space-order: $SPACE_ORDER"
        echo "mpi: $DEVITO_MPI"

        apptainer exec --nv ${IMAGE_PATH} bash -c \
        "export DEVITO_LANGUAGE=$devito_lang && \
        export DEVITO_PLATFORM=nvidiaX && \
        export DEVITO_ARCH=$devito_arch && \
        export DEVITO_MPI=$DEVITO_MPI && \
        mpirun -np $SLURM_GPUS_ON_NODE python3 -m devitotuner Simple V100_cimatec /v100_so_"$SPACE_ORDER"_d_"$DOMAIN_SIZE"_gpu_"$SLURM_GPUS_ON_NODE".json $BENCHMARK_SCRIPT run \
        -d $DOMAIN_SIZE $DOMAIN_SIZE $DOMAIN_SIZE \
        -so $SPACE_ORDER \
        -tn $FINAL_TIME"
        echo "= END ="
    done
done
