



sbatch \
    --gpus=$2 \
    --ntasks=$2 \
    --output=${1}_${2}.txt \
    --error=${1}_${2}.txt \
    $1