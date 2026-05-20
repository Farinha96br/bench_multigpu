#!/bin/bash
#SBATCH --begin=now
#SBATCH --time=2-00:00:00
#SBATCH --partition=large
#SBATCH --job-name=open
#SBATCH --cpus-per-task=4
#SBATCH --mem=50G

if [ -z "$SLURM_GPUS_ON_NODE" ] || [ "$SLURM_GPUS_ON_NODE" -eq 0 ]; then
    echo "Error: SLURM_GPUS_ON_NODE is not set or is 0" >&2
    exit 1
fi

module load apptainer 

export IMAGE_PATH=/home/afarinha_local/devitopro_bench.sif
export APPTAINER_TMPDIR=/home/afarinha_local/apptainertmpdir
export APPTAINER_CACHEDIR=/home/afarinha_local/apptainercachedir
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

export BENCHMARK_SCRIPT=/app/devitopro/submodules/devito/benchmarks/user/benchmark.py


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

            echo "run-number: $j"
            echo "domain-size: $DOMAIN_SIZE"
            echo "space-order: $SPACE_ORDER"
            echo "mpi: $DEVITO_MPI"

            apptainer exec --nv ${IMAGE_PATH} bash -c \
            "export DEVITO_LANGUAGE=$devito_lang && \
            export DEVITO_PLATFORM=nvidiaX && \
            export DEVITO_ARCH=$devito_arch && \
            export DEVITO_MPI=$DEVITO_MPI && \
            mpirun -np $SLURM_GPUS_ON_NODE python3 -m devitotuner Forward dgx/h200_so_"$SPACE_ORDER"_d_"$DOMAIN_SIZE"_gpu_"$SLURM_GPUS_ON_NODE".json $BENCHMARK_SCRIPT run \
            -P acoustic \
            -d $DOMAIN_SIZE $DOMAIN_SIZE $DOMAIN_SIZE \
            -so $SPACE_ORDER \
            -s 20.0 20.0 20.0  \
            --nbl 0 \
            --tn 500"
            echo "= END ="
        done
    done
done
