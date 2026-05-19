#!/bin/bash
#SBATCH --begin=now
#SBATCH --time=0-12:00:00
#SBATCH --partition=large
#SBATCH --job-name=open
#SBATCH --output=dgx_h200/pro_tunning.txt
#SBATCH --error=dgx_h200/pro_tunning.txt
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=4
#SBATCH --gpus=4
#SBATCH --mem=100G

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
gpunum=(1 2 4)

bash clone_and_fix.sh

for space_order_idx in "${!space_orders[@]}"
    do
        SPACE_ORDER=${space_orders[$space_order_idx]}
    for domain_size in "${domain_sizes[@]}"
    do
        DOMAIN_SIZE=$domain_size
            for i in "${gpunum[@]}"
            do
                if [ $i -eq 1 ]
                then
                    DEVITO_MPI=0
                else
                    DEVITO_MPI="diag2"
                fi
                GPU_NUM=$i
                # now the repetitions
                for j in $(seq 1 $repeats)
                do
                    echo "= START ="
                    echo "TUNING WITH"
                    echo "run-number: $j"
                    echo "domain-size: $DOMAIN_SIZE"
                    echo "space-order: $SPACE_ORDER"
                    echo "final-time: $FINAL_TIME" 
                    echo "operator: $OPERATOR"
                    echo "devito-version: pro"
                    echo "gpu-num: $GPU_NUM"
                    echo "mpi: $DEVITO_MPI"

                    apptainer exec --nv ${IMAGE_PATH} bash -c \
                    "export DEVITO_LANGUAGE=$devito_lang && \
                    export DEVITO_PLATFORM=nvidiaX && \
                    export DEVITO_ARCH=$devito_arch && \
                    export DEVITO_MPI=$DEVITO_MPI && \
                    mpirun -np $GPU_NUM python3 -m devitotuner Forward dgx_h200/h200_so_"$SPACE_ORDER"_d_"$DOMAIN_SIZE"_gpu_"$GPU_NUM".json $BENCHMARK_SCRIPT run \
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
    done
done
