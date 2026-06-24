# using openACC:
# This command works:
# python3 minimal_acoustic.py -d 1024 1024 1024 -so 4 -tn 100 -opt "('advanced', {'linearize':False,'index-mode':'int64'})"

# using CUDA:
# python3 -m devitopro minimal_acoustic.py -d 1024 1024 1024 -so 4 -tn 100 -opt "('advanced', {'linearize':False,'index-mode':'int64'})"

import os
os.environ.setdefault("MPLCONFIGDIR", "/tmp/matplotlib_cache")

import numpy as np
import argparse
import ast
from devito import (Grid, TimeFunction, Function, Eq, Operator,
                    SparseTimeFunction, solve, print_state)



CONFIGS_PATH="/home/andre.farinha/paper_multigpu/bench_multigpu/all_configs.json"

parser = argparse.ArgumentParser()

parser.add_argument("-d",   "--dimension",  nargs=3, type=int, default=[128, 128, 128], metavar=("NX", "NY", "NZ"))
parser.add_argument("-so",  "--spaceorder", type=int, default=8)
parser.add_argument("-tn",  "--timesteps",  type=int, default=500)
parser.add_argument("-pro", type=bool, default=False)
parser.add_argument("-gpumodel", type=str, default="DummyGPU")
parser.add_argument("-machine", type=str, default="DummyMachine")
parser.add_argument("-ngpus", type=int, default=1)
args = parser.parse_args()

if args.pro:
    from devitopro import *



gpucount = args.ngpus

if args.pro:
    
    if args.gpumodel == "DummyGPU":
        # error
        print("Error: Please specify a valid GPU model using the -gpumodel argument.")
        exit(1)
    if args.machine == "DummyMachine":
        # error
        print("Error: Please specify a valid machine using the -machine argument.")
        exit(1)

    from tuner_organizer import get_config



    opt_opts = get_config(CONFIGS_PATH, args.machine, args.gpumodel, int(args.spaceorder), int(args.dimension[0]), gpucount)
    #print("Arguments:", opt_opts)
    
# --- Model parameters ---
origin = (0.0, 0.0, 0.0)
shape = tuple(args.dimension)
extent = (4000.0, 4000.0, 4000.0)

spacing = (extent[0] / (shape[0] - 1), extent[1] / (shape[1] - 1), extent[2] / (shape[2] - 1))
t0, tn = 0.0, float(args.timesteps)
dt = 1.0
nt = int((tn - t0) / dt) + 1
print("nt:", nt)
so = args.spaceorder


grid = Grid(
    origin=origin,
    shape=shape,
    extent=extent,
)


# Velocity model
vp = Function(name='Vp', grid=grid, space_order=so)
vp.data[:] = 1.5

# Create Pressure
u = TimeFunction(name='u', grid=grid, space_order=so, time_order=2)

# Acoustic wave 
#   u_tt = vp^2 * laplacian(u)
pde = Eq(u.dt2, vp**2 * u.laplace)
#print("PDE:", pde)
stencil = Eq(u.forward, solve(pde, u.forward))
#print("Stencil:", stencil)

gridPoints=(shape[0]+2*args.spaceorder)*(shape[1]+2*args.spaceorder)*(shape[2]+2*args.spaceorder)




if args.pro:
    print("Running operator with devitopro, and opt:", opt_opts)
    op = Operator([stencil], name="Simple", opt=opt_opts)
else:
    if gridPoints > 2**31:
        print("Max int32 detected, using int64 indexing")
        opt_opts = (('advanced', {'index-mode': 'int64'}))
        op = Operator([stencil], name="Simple", opt=opt_opts)
    else:
        print("Running operator with devito")
        op = Operator([stencil], name="Simple")

# Exec:
op.apply(time=nt - 1, dt=dt)

print_state()