#!/bin/bash
#SBATCH --begin=now
#SBATCH --time=0-12:00:00
#SBATCH --partition=lncc-h100
#SBATCH --job-name=Pro
#SBATCH --cpus-per-task=4
#SBATCH --mem=50G



GPUCOUNT=$SLURM_NTASKS


if [ -z "$GPUCOUNT" ] || [ "$GPUCOUNT" -eq 0 ]; then
    echo "Error: GPUCOUNT is not set or is 0" >&2
    exit 1
fi

export IMAGE_PATH=/prj/cadase/andre.bosio/devitopro_update20260605.sif
export APPTAINER_TMPDIR=/prj/cadase/andre.bosio/apptainertmpdir
export APPTAINER_CACHEDIR=/prj/cadase/andre.bosio/apptainercachedir
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

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

            singularity exec --nv ${IMAGE_PATH} bash -c \
            "export DEVITO_LANGUAGE=$devito_lang && \
            export DEVITO_PLATFORM=nvidiaX && \
            export DEVITO_ARCH=$devito_arch && \
            export DEVITO_LOGGING=DEBUG && \
            export DEVITO_MPI=$DEVITO_MPI && \
            $EXEC_CMD $BENCHMARK_SCRIPT \
            -d $DOMAIN_SIZE $DOMAIN_SIZE $DOMAIN_SIZE \
            -so $SPACE_ORDER \
            -tn $FINAL_TIME \
            -pro True \
            -machine H100_SDumont \
            -gpumodel H100 \
            -ngpus $GPUCOUNT"

            echo "= END ="
                
        done
    done
done

echo "All runs completed."
