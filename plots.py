# reads JLD file in python, rearranges and plots

import sys
import h5py
import numpy as np

import matplotlib.pyplot as plt

year = int(sys.argv[1])
f = "data/corn_800_daily_grow_count_{}.jld".format(year)
h5 = h5py.File(f, "r")
gc = h5['grow_count']

# this is slow -- converts h5 to numpy matrix
mp = np.zeros((365, 720, 1440))

for i in range(720):
    for j in range(1440):
        st = gc[i,j]
        vals = h5[st][:]
        mp[:, i, j] = vals / 42

for i in range(mp.shape[0]): 
    print(i)
    fig, ax = plt.subplots(figsize=(10,7)) 
    cb = ax.matshow(np.rot90(mp[i, :, :].T), vmin=0, vmax=1, cmap='afmhot_r', origin='upper') 
    plt.colorbar(cb, orientation="horizontal", pad=0) 
    plt.axis('off') 
    plt.title("Grow Probability", y=0.97, fontsize=18, loc="left") 
    plt.suptitle("Day {} of year {}".format(i+1, year), y=0.8, x=0.055, horizontalalignment="left") 
    plt.tight_layout() 
    plt.savefig('data/{}'.format(year) + '_' + '{0:03d}.png'.format(i+1), dpi=300, pad_inches=0, bbox_inches="tight") 
    plt.close() 




