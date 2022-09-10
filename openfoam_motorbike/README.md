# OpenFOAM MotorBike Example

The motorbike example is an example workload provided by OpenFOAM that simulates airflow over a motorbike and it's rider.

This documentation provides a description of how to execute the motorbike example on a slurm cluster.


## Create a Singularity Container with OpenFOAM v10

[Singularity](https://docs.sylabs.io/guides/3.10/user-guide/introduction.html) is a container platform for HPC environments. 

Using a container, we can build and install OpenFOAM v10 and it's dependencies and package up whatever we need into a single image file.

We can build an OpenFOAM v10 singularity image using a docker or another singularity image as base.

Here we are gonna use a docker image with OpenFOAM v10 and MPICH 3.2 built on top of a CentOS 7 operating system.

In case, you would like to build OpenFOAM v10 from source, the scripts are available below:

- [Build OpenFOAM from source - Ubuntu 20.04](scripts/build-openfoam-from-source-ubuntu.sh)
- [Build OpenFOAM from source - CentOS 7](scripts/build-openfoam-from-source-centos.sh)

To create a Singularity image for OpenFOAM, we must write a definition file for it.

For example, we can create the [`openfoam.def`](scripts/openfoam.def) file.

Now we use the `singularity build` command to build the singularity container image (`openfoam10.sif`)

`singularity build -f openfoam10.sif openfoam.def`

This `openfoam10.sif` is available for download [here](https://omnivector-public-assets.s3.us-west-2.amazonaws.com/singularity/openfoam10.sif)

To download it, we can use:

`curl -o openfoam10.sif --location "https://omnivector-public-assets.s3.us-west-2.amazonaws.com/singularity/openfoam10.sif"`

or 

`wget https://omnivector-public-assets.s3.us-west-2.amazonaws.com/singularity/openfoam10.sif`


## Run the motorBike example on the cluser

- Directly on the cluster
    - Sequential
    - Parallel (MPI)
    
- Using Jobbergate
    - Sequential
    - Parallel (MPI)

