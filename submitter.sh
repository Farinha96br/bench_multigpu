


job_name="${1%.sh}"

sbatch \
    --gpus=$2 \
    --ntasks=$2 \
    --output=${job_name}_${2}.txt \
    --error=${job_name}_${2}.txt \
    $1