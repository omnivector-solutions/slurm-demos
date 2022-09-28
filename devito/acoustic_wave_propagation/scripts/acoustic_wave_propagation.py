"""
This code is based on Devito's tutorial available in
https://github.com/devitocodes/devito/blob/master/examples/seismic/tutorials/01_modelling.ipynb
"""

import numpy as np
import os
import matplotlib.pyplot as plt
from matplotlib import cm
from mpl_toolkits.axes_grid1 import make_axes_locatable
from examples.seismic import Model
from examples.seismic import TimeAxis
from examples.seismic import RickerSource
from examples.seismic import Receiver
from devito import TimeFunction
from devito import Eq, solve
from devito import Operator


def plot_velocity(model, source=None, receiver=None,
                  colorbar=True, cmap="jet", file_name="velocity"):
    """
    Plot a two-dimensional velocity field from a seismic `Model`
    object. Optionally also includes point markers for sources and receivers.

    Adapted from:
    https://github.com/devitocodes/devito/blob/b1e8fffdee7d6b556ff19a372d69ed1aebee675a/examples/seismic/plotting.py#L50

    Parameters
    ----------
    model : Model
        Object that holds the velocity model.
    source : array_like or float
        Coordinates of the source point.
    receiver : array_like or float
        Coordinates of the receiver points.
    colorbar : bool
        Option to plot the colorbar.
    """
    domain_size = 1.e-3 * np.array(model.domain_size)
    extent = [model.origin[0], model.origin[0] + domain_size[0],
              model.origin[1] + domain_size[1], model.origin[1]]

    slices = tuple(slice(model.nbl, -model.nbl) for _ in range(2))
    if getattr(model, 'vp', None) is not None:
        field = model.vp.data[slices]
    else:
        field = model.lam.data[slices]
    plot = plt.imshow(np.transpose(field), animated=True, cmap=cmap,
                      vmin=np.min(field), vmax=np.max(field),
                      extent=extent)
    plt.xlabel('X position (km)')
    plt.ylabel('Depth (km)')

    # Plot source points, if provided
    if receiver is not None:
        plt.scatter(1e-3*receiver[:, 0], 1e-3*receiver[:, 1],
                    s=25, c='green', marker='D')

    # Plot receiver points, if provided
    if source is not None:
        plt.scatter(1e-3*source[:, 0], 1e-3*source[:, 1],
                    s=25, c='red', marker='o')

    # Ensure axis limits
    plt.xlim(model.origin[0], model.origin[0] + domain_size[0])
    plt.ylim(model.origin[1] + domain_size[1], model.origin[1])

    # Create aligned colorbar on the right
    if colorbar:
        ax = plt.gca()
        divider = make_axes_locatable(ax)
        cax = divider.append_axes("right", size="5%", pad=0.05)
        cbar = plt.colorbar(plot, cax=cax)
        cbar.set_label('Velocity (km/s)')

    # create the destination dir
    os.makedirs("plots", exist_ok=True)

    plt.savefig("plots/{}.png".format(file_name), format="png")

    plt.close()

    print("Image saved in plots/{}.png".format(file_name))


def plot_shotrecord(rec, model, t0, tn, colorbar=True, file_name="shotrecord"):
    """
    Plot a shot record (receiver values over time).

    Adapted from:
    https://github.com/devitocodes/devito/blob/b1e8fffdee7d6b556ff19a372d69ed1aebee675a/examples/seismic/plotting.py#L105

    Parameters
    ----------
    rec :
        Receiver data with shape (time, points).
    model : Model
        object that holds the velocity model.
    t0 : int
        Start of time dimension to plot.
    tn : int
        End of time dimension to plot.
    """
    scale = np.max(rec) / 10.
    extent = [model.origin[0], model.origin[0] + 1e-3*model.domain_size[0],
              1e-3*tn, t0]

    plot = plt.imshow(rec, vmin=-scale, vmax=scale,
                      cmap=cm.gray, extent=extent)

    plt.xlabel('X position (km)')
    plt.ylabel('Time (s)')

    # Create aligned colorbar on the right
    if colorbar:
        ax = plt.gca()
        divider = make_axes_locatable(ax)
        cax = divider.append_axes("right", size="5%", pad=0.05)
        plt.colorbar(plot, cax=cax)

    # create the destination dir
    os.makedirs("plots", exist_ok=True)

    plt.savefig("plots/{}.png".format(file_name), format="png")

    plt.close()

    print("Image saved in plots/{}.png".format(file_name))


if __name__ == '__main__':

    # Number of grid point (nx, nz)
    shape = (101, 101)

    # Grid spacing in m. The domain size is now 1km by 1km
    spacing = (10., 10.)

    # What is the location of the top left corner. This is necessary to define
    # the absolute location of the source and receivers
    origin = (0., 0.)

    # Define a velocity profile. The velocity is in km/s
    v = np.empty(shape, dtype=np.float32)
    v[:, :51] = 1.5
    v[:, 51:] = 2.5

    # With the velocity and model size defined,
    # we can create the seismic model that encapsulates this properties.
    # We also define the size of the absorbing layer as 10 grid points.
    model = Model(vp=v, origin=origin, shape=shape, spacing=spacing,
                  space_order=2, nbl=10, bcs="damp")

    # Simulation starts a t=0
    t0 = 0.

    # Simulation last 1 second (1000 ms)
    tn = 1000.

    # Time step from model grid spacing
    dt = model.critical_dt

    time_range = TimeAxis(start=t0, stop=tn, step=dt)

    # Source peak frequency is 10Hz (0.010 kHz)
    f0 = 0.010
    src = RickerSource(name='src', grid=model.grid, f0=f0,
                       npoint=1, time_range=time_range)

    # First, position source centrally in all dimensions, then set depth
    src.coordinates.data[0, :] = np.array(model.domain_size) * .5

    # Depth is 20m
    src.coordinates.data[0, -1] = 20.

    # Create symbol for 101 receivers
    rec = Receiver(name='rec', grid=model.grid,
                   npoint=101, time_range=time_range)

    # Prescribe even spacing for receivers along the x-axis
    rec.coordinates.data[:, 0] = np.linspace(0, model.domain_size[0], num=101)

    # Depth is 20m
    rec.coordinates.data[:, 1] = 20.

    # Define the wavefield with the size of the model and the time dimension
    u = TimeFunction(name="u", grid=model.grid, time_order=2, space_order=2)

    # We can now write the PDE
    pde = model.m * u.dt2 - u.laplace + model.damp * u.dt

    stencil = Eq(u.forward, solve(pde, u.forward))

    # Finally we define the source injection and receiver read
    # function to generate the corresponding code
    src_term = src.inject(field=u.forward, expr=src * dt**2 / model.m)

    # Create interpolation expression for receivers
    rec_term = rec.interpolate(expr=u.forward)

    op = Operator([stencil] + src_term + rec_term, subs=model.spacing_map)

    op(time=time_range.num-1, dt=model.critical_dt)

    # We can now show the source and receivers within our domain:
    # Red dot: Source location
    # Green dots: Receiver locations (every 4th point)
    plot_velocity(model, source=src.coordinates.data,
                  receiver=rec.coordinates.data[::4, :], file_name='model')

    # Plot the resulting shot record
    plot_shotrecord(rec.data, model, t0, tn)
