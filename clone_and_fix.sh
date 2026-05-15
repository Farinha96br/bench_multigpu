#!/bin/bash
# This script just changes the utils.py file from the cloned devito repository

if [ ! -d "devito" ]; then
    git clone https://github.com/devitocodes/devito.git
else
    echo "Repository 'devito' already exists, skipping clone."
fi

# find and replace the string from utils:
UTILS_FILE=devito/examples/seismic/utils.py
BENCHMARK_FILE=devito/benchmarks/user/benchmark.py

if cat "$UTILS_FILE" | grep -q "nrecx = model\.shape\[0\]"; then
    sed -i 's/nrecx = model\.shape\[0\]/nrecx = 1/' "$UTILS_FILE"
    sed -i 's/nrecy = model\.shape\[1\]/nrecy = 1/' "$UTILS_FILE"
    echo "utils.py patched successfully."
else
    echo "utils.py already patched, skipping."
fi

# patch benchmark.py: add print_state import and call
if cat "$BENCHMARK_FILE" | grep -q "from devito.parameters import print_state"; then
    echo "benchmark.py already patched, skipping."
else
    sed -i 's/from devito.operator.profiling import PerformanceSummary/from devito.operator.profiling import PerformanceSummary\nfrom devito.parameters import print_state/' "$BENCHMARK_FILE"
    sed -i 's/    benchmark(standalone_mode=False)/    benchmark(standalone_mode=False)\n\n    print_state()/' "$BENCHMARK_FILE"
    echo "benchmark.py patched successfully."
fi
