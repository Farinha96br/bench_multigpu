import os
import sys
import re
import json
os.environ.setdefault("MPLCONFIGDIR", "/tmp/matplotlib_cache")

from devitotuner.wrapper import retrieve_best

MAIN_FILE = "all_configs.json"

def check_path_format(path):
    pattern = r"^[a-zA-Z0-9_]+/[a-zA-Z0-9_]+_so_\d+_d_\d+_gpu_\d+\.json$"
    if not re.match(pattern, path):
        print("The path is not in the correct format. Please use the format: string/string_so_int_d_int_gpu_int.json")
        sys.exit(1)

def exctract_info_from_path(path):
    pattern = r"^([a-zA-Z0-9_]+)/([a-zA-Z0-9_]+)_so_(\d+)_d_(\d+)_gpu_(\d+)\.json$"
    match = re.match(pattern, path)
    dict = {}
    if match:
        machine = match.group(1)
        gpu_model = match.group(2)
        space_order = int(match.group(3))
        domain_side = int(match.group(4))
        gp_count = int(match.group(5))
        return machine, gpu_model, space_order, domain_side, gp_count
    else:
        print("The path is not in the correct format. Please use the format: string/string_so_int_d_int_gpu_int.json")
        sys.exit(1)

def organize_parameters(path):
    # check if the formating tis correct
    check_path_format(path)
    # gather the parameters from the path
    machine, gpu_model, space_order, domain_side, gp_count = exctract_info_from_path(path)
    # gather the options from the path
    best_opt = retrieve_best(path)

    dict = {
        "machine": machine,
        "gpu_model": gpu_model,
        "space_order": space_order,
        "domain_side": domain_side,
        "gp_count": gp_count,
        "best_opt": tuple(best_opt[0:2])
    }
    return dict




def save_to_main_file(entry):
    if os.path.exists(MAIN_FILE) and os.path.getsize(MAIN_FILE) > 0:
        with open(MAIN_FILE, "r") as f:
            configs = json.load(f)
    else:
        configs = []

    key_fields = ("machine", "gpu_model", "space_order", "domain_side", "gp_count")
    already_exists = any(
        all(c[k] == entry[k] for k in key_fields) for c in configs
    )

    if already_exists:
        print("Entry already exists in all_configs.json, skipping.")
    else:
        configs.append(entry)
        with open(MAIN_FILE, "w") as f:
            json.dump(configs, f, indent=4)
        print("Entry added to all_configs.json.")


path = sys.argv[1]
if path.endswith(".json"):
    entry = organize_parameters(path)
    print(entry)
    save_to_main_file(entry)
if path.endswith("/"):
    files = sorted(os.listdir(path))
    for file in files:
        if file.endswith(".json"):
            full_path = os.path.join(path, file)
            entry = organize_parameters(full_path)
            print(entry)
            save_to_main_file(entry)


def get_config(all_configs_path, machine, gpu_model, space_order, domain_side, gp_count):
    """Retrieve best_opt tuple from given all_configs JSON file path.

    all_configs_path: path to the JSON file containing configurations.
    """
    if os.path.exists(all_configs_path) and os.path.getsize(all_configs_path) > 0:
        with open(all_configs_path, "r") as f:
            configs = json.load(f)
    else:
        print("No configurations found.")
        return None

    for config in configs:
        if (config.get("machine") == machine and
            config.get("gpu_model") == gpu_model and
            config.get("space_order") == space_order and
            config.get("domain_side") == domain_side and
            config.get("gp_count") == gp_count):
            return tuple(config.get("best_opt", ()))

    print("Configuration not found.")
    return None


#config = get_config(MAIN_FILE, "V100_cimatec", "V100", 4, 256, 2)
#
#print("====================")
#print(config)