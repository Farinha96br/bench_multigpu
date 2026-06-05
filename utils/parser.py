import re


CONFIG_KEYS = [
    'run-number', 'domain-size', 'space-order', 'time-steps',
    'devito-version', 'gpu-num', 'mpi', 'platform', 'compiler',
    'language', 'topology', 'first-touch', 'ignore-unknowns',
    'log-level', 'jit-backdoor', 'safe-math', 'autopadding',
    'deviceid', 'autotuning', 'develop-mode', 'opt', 'opt-options',
    'profiling',
]


def split_blocks(text):
    """Split log text into individual run blocks delimited by = START = / = END =."""
    blocks = []
    for match in re.finditer(r'= START =(.*?)= END =', text, re.DOTALL):
        blocks.append(match.group(1).strip())
    return blocks


def parse_config(block):
    """Extract configuration key-value pairs from a run block.

    When a key appears more than once (e.g. 'mpi'), the first occurrence wins
    so that the MPI mode value is preserved over the boolean echo that follows.
    """
    config = {}
    for line in block.splitlines():
        line = line.strip()
        if ':' not in line:
            continue
        key, _, value = line.partition(':')
        key = key.strip()
        if key not in CONFIG_KEYS or key in config:
            continue
        config[key] = value.strip()
    return config


def parse_runtime(block):
    """Return the operator runtime in seconds from a run block, or None."""
    match = re.search(r"Operator `Simple` ran in\s+([\d.]+)\s+s", block)
    if match:
        return float(match.group(1))
    return None


def parser_runtime_wo(block):
    """Return the global performance time in seconds from a run block, or None.

    Example line:
    Global performance <w/o setup>: [210.27 s, 20.43 GPts/s]
    """
    match = re.search(r"Global performance.*\[\s*([\d.]+)\s*s,", block)
    if match:
        return float(match.group(1))
    return None


def parse_run(block):
    """Return a dict with config fields and runtime for a single run block."""
    result = parse_config(block)
    result['runtime_s'] = parser_runtime_wo(block)
    return result


def parse_file(filepath):
    """Parse all runs from a log file and return a list of dicts."""
    with open(filepath) as f:
        text = f.read()
    return [parse_run(block) for block in split_blocks(text)]
