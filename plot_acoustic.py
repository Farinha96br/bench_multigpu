import os
os.environ.setdefault("MPLCONFIGDIR", "/tmp/matplotlib_cache")
import numpy as np
import matplotlib.pyplot as plt

u = np.load("u_last.npy")   # shape: (nx, ny, nz)
rec = np.load("rec_trace.npy")  # shape: (nt, 1)

nx, ny, nz = u.shape
mid_x = nx // 2
mid_y = ny // 2
mid_z = nz // 2

fig, axes = plt.subplots(1, 3, figsize=(15, 4))

slices = [
    (u[mid_x, :, :], f"XY slice at x={mid_x}", "Y", "Z"),
    (u[:, mid_y, :], f"XZ slice at y={mid_y}", "X", "Z"),
    (u[:, :, mid_z], f"XY slice at z={mid_z}", "X", "Y"),
]

for ax, (data, title, xlabel, ylabel) in zip(axes, slices):
    vmax = np.percentile(np.abs(data), 99)
    im = ax.imshow(data.T, origin="lower", aspect="auto",
                   cmap="seismic", vmin=-vmax, vmax=vmax)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    plt.colorbar(im, ax=ax, shrink=0.8)

plt.suptitle("Acoustic wavefield — last time step")
plt.tight_layout()
plt.savefig("u_last_slices.png", dpi=150)
print("Saved u_last_slices.png")

# Receiver trace
fig2, ax2 = plt.subplots(figsize=(8, 3))
ax2.plot(rec[:, 0])
ax2.set_xlabel("Time step")
ax2.set_ylabel("Amplitude")
ax2.set_title("Receiver trace")
plt.tight_layout()
plt.savefig("rec_trace.png", dpi=150)
print("Saved rec_trace.png")
