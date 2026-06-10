


job_name="${1%.sh}"

sbatch \
    --ntasks=$2 \
    --output=${job_name}_${2}.txt \
    --error=${job_name}_${2}.txt \
    -A usp-2024.1 \
    $1