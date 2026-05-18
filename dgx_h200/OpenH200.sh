#!/bin/bash
#SBATCH --begin=now
#SBATCH --time=0-12:00:00
#SBATCH --partition=large
#SBATCH --job-name=open
#SBATCH --output=dgx_h200/open.txt
#SBATCH --error=dgx_h200/open.txt
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=4
#SBATCH --gpus=4
#SBATCH --mem=100G

module load apptainer 

export IMAGE_PATH=/home/afarinha_local/devito_nvidia-nvc12-dev-amd64.sif
export APPTAINER_TMPDIR=/home/afarinha_local/apptainertmpdir
export APPTAINER_CACHEDIR=/home/afarinha_local/apptainercachedir
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

export BENCHMARK_SCRIPT=devito/benchmarks/user/benchmark.py


devito_lang=openacc
devito_arch=nvc
devito_platform=nvidiaX

space_orders


domain_sizes=(256 512 1024)
space_orders=(2 4 8 2 4 8)
#            4k   4k    4k    400 400  400
final_times=(11425 10349 9680 1138 1032 965) 
gpunum=(1 2 4)

repeats=5

#SO=8:   9680   965
#SO=4:  10349   1032
#SO=2:  11425   1138

bash clone_and_fix.sh

for space_order_idx in "${!space_orders[@]}"
    do
        SPACE_ORDER=${space_orders[$space_order_idx]}
        FINAL_TIME=${final_times[$space_order_idx]}
    for domain_size in "${domain_sizes[@]}"
    do
        DOMAIN_SIZE=$domain_size
            for i in "${gpunum[@]}"
            do
                if [ $i -eq 1 ]
                then
                    DEVITO_MPI=0
                else
                    DEVITO_MPI=1
                fi
                GPU_NUM=$i
                # now the repetitions
                for j in $(seq 1 $repeats)
                do
                    echo "= START ="
                    echo "run-number: $j"
                    echo "domain-size: $DOMAIN_SIZE"
                    echo "space-order: $SPACE_ORDER"
                    echo "final-time: $FINAL_TIME" 
                    echo "operator: $OPERATOR"
                    echo "devito-version: open"
                    echo "gpu-num: $GPU_NUM"
                    echo "mpi: $DEVITO_MPI"

                    apptainer exec --nv ${IMAGE_PATH} bash -c \
                    "export DEVITO_LANGUAGE=openacc && \
                    export DEVITO_PLATFORM=nvidiaX && \
                    export DEVITO_ARCH=nvc && \
                    source /venv/bin/activate && \
                    export PYTHONPATH=devito/ && \
                    export DEVITO_MPI=$DEVITO_MPI && \
                    mpirun -np $GPU_NUM python3 $BENCHMARK_SCRIPT run \
                    -P acoustic \
                    -d $DOMAIN_SIZE $DOMAIN_SIZE $DOMAIN_SIZE \
                    -so $SPACE_ORDER \
                    -s 20.0 20.0 20.0  \
                    --nbl 0 \
                    --tn $FINAL_TIME"

                    echo "= END ="
                done
            done
        done
    done
done
