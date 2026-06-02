# using openACC:
# This command works:
# python3 minimal_acoustic.py -d 1024 1024 1024 -so 4 -tn 100 -opt "('advanced', {'linearize':False,'index-mode':'int64'})"

# using CUDA:
# python3 -m devitopro minimal_acoustic.py -d 1024 1024 1024 -so 4 -tn 100 -opt "('advanced', {'linearize':False,'index-mode':'int64'})"

import os
import tempfile
os.environ.setdefault("MPLCONFIGDIR", "/tmp/matplotlib_cache")

import numpy as np
import argparse
import ast
from devito import (Grid, TimeFunction, Function, Eq, Operator,
                    SparseTimeFunction, solve, print_state)

from devitopro import *
from devitotuner import tuner_enabled


tmp = tempfile.NamedTemporaryFile(suffix='.json')

parser = argparse.ArgumentParser()
parser.add_argument("-d",   "--dimension",  nargs=3, type=int, default=[128, 128, 128], metavar=("NX", "NY", "NZ"))
parser.add_argument("-so",  "--spaceorder", type=int, default=8)
parser.add_argument("-tn",  "--timesteps",  type=int, default=500)
parser.add_argument("-opt", "--options",    type=str, default="('advanced')")
args = parser.parse_args()



opt_val = ast.literal_eval(args.options)


# --- Model parameters ---
origin = (0.0, 0.0, 0.0)
shape = tuple(args.dimension)
extent = (4000.0, 4000.0, 4000.0)

spacing = (extent[0] / (shape[0] - 1), extent[1] / (shape[1] - 1), extent[2] / (shape[2] - 1))
t0, tn = 0.0, float(args.timesteps)
dt = 1.0
nt = int((tn - t0) / dt) + 1
so = args.spaceorder


grid = Grid(
    origin=origin,
    shape=shape,
    extent=extent,
)

import mpi4py.MPI as MPI
comm = MPI.COMM_WORLD
rank = comm.Get_rank()

#if rank == 0:
#    print(print_state())

# Velocity model
with tuner_enabled("Simple",tmp.name,('advanced',{'linearize':False})):

    vp = Function(name='Vp', grid=grid, space_order=so)
    vp.data[:] = 1.5

    # Create Pressure
    u = TimeFunction(name='u', grid=grid, space_order=so, time_order=2)

    # Create Ricker Source
    ## src = SparseTimeFunction(name='RickerSrc', grid=grid, npoint=1, nt=nt)
    ## src.coordinates.data[0, :] = np.array(
    ##     [spacing[0] * shape[0] // 2,           
    ##      spacing[1] * shape[1] // 2,  
    ##      spacing[2] * shape[2] // 2]            
    ## )
    ## 
    ## f0 = 0.025  # dominant frequency in kHz (~25 Hz)
    ## t = np.linspace(t0, tn, nt)
    ## tau = t - 1.0 / f0
    ## src.data[:, 0] = (
    ##     (1.0 - 2.0 * (np.pi * f0 * tau) ** 2)
    ##     * np.exp(-(np.pi * f0 * tau) ** 2)
    ## )
    ## 
    ## # Single receiver
    ## rec = SparseTimeFunction(name='rec', grid=grid, npoint=1, nt=nt)
    ## rec.coordinates.data[0, :] = np.array([
    ##     spacing[0] * shape[0] // 2,           
    ##     spacing[1] * shape[1] // 8, 
    ##     spacing[2] * shape[2] // 2]            
    ## )

    # Acoustic wave 
    #   u_tt = vp^2 * laplacian(u)
    pde = Eq(u.dt2, vp**2 * u.laplace)
    #print("PDE:", pde)
    stencil = Eq(u.forward, solve(pde, u.forward))
    #print("Stencil:", stencil)
    ## src_term = src.inject(field=u.forward, expr=src * dt**2 * vp**2)
    ## rec_term = rec.interpolate(expr=u)

    if rank == 0:
        print("arguments:", opt_val)
    op = Operator([stencil], name="Simple")

    # Exec:
    op.apply(time=nt - 1, dt=dt)


content = eval(tmp.file.read())