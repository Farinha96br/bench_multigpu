get_best_opt() {
    local machine=$1 gpu=$2 so=$3 ds=$4 gp=$5 file=$6
    jq -r --arg machine "$machine" \
          --arg gpu "$gpu" \
          --argjson so "$so" \
          --argjson ds "$ds" \
          --argjson gp "$gp" \
       '.[] | select(
            .machine == $machine and
            .gpu_model == $gpu and
            .space_order == $so and
            .domain_side == $ds and
            .gp_count == $gp
       ) | .best_opt' \
       $file
}

# usage
best=$(get_best_opt dgx h200 2 256 4 all_configs.json)
echo "$best"