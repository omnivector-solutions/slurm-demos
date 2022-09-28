"""
This code is based on Devito's tutorial available in
https://github.com/devitocodes/devito/blob/master/examples/seismic/tutorials/03_fwi.ipynb
"""

import numpy as np
import os
from examples.seismic import demo_model
from examples.seismic import AcquisitionGeometry
from examples.seismic.acoustic import AcousticWaveSolver
from devito import Eq, Operator
from devito import Function, norm
from examples.seismic import Receiver
from devito import mmax
from devito import Min, Max
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable


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


# Computes the residual between observed and synthetic data into the residual
def compute_residual(residual, dobs, dsyn):
    if residual.grid.distributor.is_parallel:
        # If we run with MPI, we have to compute the residual via an operator
        # First make sure we can take the difference and that receivers are
        # at the same position
        assert np.allclose(dobs.coordinates.data[:], dsyn.coordinates.data)
        assert np.allclose(residual.coordinates.data[:], dsyn.coordinates.data)
        # Create a difference operator
        diff_eq = Eq(
            residual,
            dsyn.subs({dsyn.dimensions[-1]: residual.dimensions[-1]}) -
            dobs.subs({dobs.dimensions[-1]: residual.dimensions[-1]})
        )

        Operator(diff_eq)()
    else:
        # A simple data difference is enough in serial
        residual.data[:] = dsyn.data[:] - dobs.data[:]

    return residual


def fwi_gradient(vp_in):
    # Create symbols to hold the gradient
    grad = Function(name="grad", grid=model.grid)
    # Create placeholders for the data residual and data
    residual = Receiver(name='residual', grid=model.grid,
                        time_range=geometry.time_axis,
                        coordinates=geometry.rec_positions)
    d_obs = Receiver(name='d_obs', grid=model.grid,
                     time_range=geometry.time_axis,
                     coordinates=geometry.rec_positions)
    d_syn = Receiver(name='d_syn', grid=model.grid,
                     time_range=geometry.time_axis,
                     coordinates=geometry.rec_positions)
    objective = 0.

    for i in range(nshots):
        # Update source location
        geometry.src_positions[0, :] = source_locations[i, :]

        # Generate synthetic data from true model
        _, _, _ = solver.forward(vp=model.vp, rec=d_obs)

        # Compute smooth data and full forward wavefield u0
        _, u0, _ = solver.forward(vp=vp_in, save=True, rec=d_syn)

        # Compute gradient from data residual and update objective function
        compute_residual(residual, d_obs, d_syn)

        objective += .5*norm(residual)**2
        solver.gradient(rec=residual, u=u0, vp=vp_in, grad=grad)

    return objective, grad


# Define bounding box constraints on the solution.
def update_with_box(vp, alpha, dm, vmin=2.0, vmax=3.5):
    """
    Apply gradient update in-place to vp with box constraint

    Notes:
    ------
    For more advanced algorithm, one will need to gather the non-distributed
    velocity array to apply constrains and such.
    """
    update = vp + alpha * dm
    update_eq = Eq(vp, Max(Min(update, vmax), vmin))
    Operator(update_eq)()


if __name__ == '__main__':

    # Number of shots to create gradient from
    nshots = 9

    # Number of receiver locations per shot
    nreceivers = 101

    # Number of outer FWI iterations
    fwi_iterations = 5

    # Number of grid point (nx, nz)
    shape = (101, 101)

    # Grid spacing in m. The domain size is now 1km by 1km
    spacing = (10., 10.)

    # Need origin to define relative source and receiver locations
    origin = (0., 0.)

    # Define true model
    model = demo_model('circle-isotropic', vp_circle=3.0, vp_background=2.5,
                       origin=origin, shape=shape, spacing=spacing, nbl=40)

    # Define initial model
    model0 = demo_model('circle-isotropic', vp_circle=2.5, vp_background=2.5,
                        origin=origin, shape=shape, spacing=spacing, nbl=40,
                        grid=model.grid)

    plot_velocity(model, file_name='true_model')
    plot_velocity(model0, file_name='initial_model')

    t0 = 0.
    tn = 1000.
    f0 = 0.010

    # First, position source centrally in all dimensions, then set depth
    src_coordinates = np.empty((1, 2))
    src_coordinates[0, :] = np.array(model.domain_size) * .5
    src_coordinates[0, 0] = 20.  # Depth is 20m

    # Define acquisition geometry: receivers
    # Initialize receivers for synthetic and imaging data
    rec_coordinates = np.empty((nreceivers, 2))
    rec_coordinates[:, 1] = np.linspace(0, model.domain_size[0],
                                        num=nreceivers)
    rec_coordinates[:, 0] = 980.

    # Geometry
    geometry = AcquisitionGeometry(model, rec_coordinates, src_coordinates,
                                   t0, tn, f0=f0, src_type='Ricker')

    solver = AcousticWaveSolver(model, geometry, space_order=4)
    true_d, _, _ = solver.forward(vp=model.vp)

    # Compute initial data with forward operator
    smooth_d, _, _ = solver.forward(vp=model0.vp)

    # Prepare the varying source locations sources
    source_locations = np.empty((nshots, 2), dtype=np.float32)
    source_locations[:, 0] = 30.
    source_locations[:, 1] = np.linspace(0., 1000, num=nshots)

    # Plot acquisition geometry
    plot_velocity(model, source=source_locations,
                  receiver=geometry.rec_positions[::4, :],
                  file_name='acquisition_geometry')

    # Compute gradient of initial model
    ff, update = fwi_gradient(model0.vp)

    # Run FWI with gradient descent
    history = np.zeros((fwi_iterations, 1))

    for i in range(0, fwi_iterations):
        # Compute the functional value and gradient for the current
        # model estimate
        phi, direction = fwi_gradient(model0.vp)

        # Store the history of the functional values
        history[i] = phi

        # Artificial Step length for gradient descent
        # In practice this would be replaced by a Linesearch (Wolfe, ...)
        # that would guarantee functional decrease
        # Phi(m-alpha g) <= epsilon Phi(m)
        # where epsilon is a minimum decrease constant
        alpha = .05 / mmax(direction)

        # Update the model estimate and enforce minimum/maximum values
        update_with_box(model0.vp, alpha, direction)

        # Log the progress made
        print('Objective value is %f at iteration %d' % (phi, i+1))

    # Plot inverted velocity model
    plot_velocity(model0, file_name='result_model')

    # Plot objective function decrease
    plt.figure()
    plt.loglog(history)
    plt.xlabel('Iteration number')
    plt.ylabel('Misift value Phi')
    plt.title('Convergence')

    # create the destination dir
    os.makedirs("plots", exist_ok=True)

    plt.savefig("plots/objective_function.png", format="png")

    plt.close()

    print("Image saved in plots/objective_function.png")
