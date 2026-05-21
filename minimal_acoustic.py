import os
os.environ.setdefault("MPLCONFIGDIR", "/tmp/matplotlib_cache")

import numpy as np
from devito import (Grid, TimeFunction, Function, Eq, Operator,
                    SparseTimeFunction, solve)

from devitopro import *

# --- Model parameters ---
origin = (0.0, 0.0, 0.0)        # origin
shape = (1024, 1024, 1024)      # grid points (x, y, z)
spacing = (10.0, 10.0, 10.0)    # spacing
extent = (shape[0] * spacing[0], shape[1] * spacing[1], shape[2] * spacing[2])  # extent
t0, tn = 0.0, 500.0             # ms
dt = 1.0                        # ms  (for benchmark does not matter)
nt = int((tn - t0) / dt) + 1    # number of time steps
so = 8                          # space order


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

# Create Ricker Source
src = SparseTimeFunction(name='RickerSrc', grid=grid, npoint=1, nt=nt)
src.coordinates.data[0, :] = np.array(
    [spacing[0] * shape[0] // 2,           
     spacing[1] * shape[1] // 2,  
     spacing[2] * shape[2] // 2]            
)

f0 = 0.025  # dominant frequency in kHz (~25 Hz)
t = np.linspace(t0, tn, nt)
tau = t - 1.0 / f0
src.data[:, 0] = (
    (1.0 - 2.0 * (np.pi * f0 * tau) ** 2)
    * np.exp(-(np.pi * f0 * tau) ** 2)
)

# Single receiver
rec = SparseTimeFunction(name='rec', grid=grid, npoint=1, nt=nt)
rec.coordinates.data[0, :] = np.array([
    spacing[0] * shape[0] // 2,           
    spacing[1] * shape[1] // 8, 
    spacing[2] * shape[2] // 2]            
)

# Acoustic wave 
#   u_tt = vp^2 * laplacian(u)
pde = Eq(u.dt2, vp**2 * u.laplace)
stencil = Eq(u.forward, solve(pde, u.forward))

src_term = src.inject(field=u.forward, expr=src * dt**2 * vp**2)
rec_term = rec.interpolate(expr=u)

op = Operator([stencil] + src_term + rec_term,name="Simple", opt=('advanced', {'index-mode':'int64'}))

# Exec:
op.apply(time=nt - 1, dt=dt)

print("Receiver trace shape:", rec.data.shape)
