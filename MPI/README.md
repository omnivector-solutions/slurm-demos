# Basic MPI Application

Here we describe how to run a basic MPI application in a slurm cluster.

The implementation is based on the tutorial available in [https://mpitutorial.com/tutorials/mpi-hello-world](https://mpitutorial.com/tutorials/mpi-hello-world/).

## Source code

The source code is available in the [mpi_test.c](scripts/mpi_test.c) file.

It can also be downloaded from [https://omnivector-public-assets.s3.us-west-2.amazonaws.com/code/mpi_test.c](https://omnivector-public-assets.s3.us-west-2.amazonaws.com/code/mpi_test.c).

For example:

```
$ wget https://omnivector-public-assets.s3.us-west-2.amazonaws.com/code/mpi_test.c
```

## Job Script

The job script [job-script.sh](scripts/job-script.sh) has the following options in the header:

```
#SBATCH -p aws                          # partition's name
#SBATCH --nodes=2                       # number of compute nodes to request
#SBATCH --ntasks=4                      # number of tasks spread across the nodes
#SBATCH -J mpi                          # job's name
#SBATCH --output=/nfs/R-%x.%j.out       # standard output file
#SBATCH --error=/nfs/R-%x.%j.err        # standard error file
#SBATCH --chdir=/nfs                    # working directory
#SBATCH -t 1:00:00                      # limit on the total run time of the job allocation
```

And it executes the steps below:

```
# donwload the code
curl -o mpi_test.c --location "https://omnivector-public-assets.s3.us-west-2.amazonaws.com/code/mpi_test.c"

# compile the code
mpicc -o mpi_test mpi_test.c

# run the code using srun
# it is gonna create 4 processes (--ntasks)
srun --mpi=pmi2 ./mpi_test
```

In a slurm cluster, you just need to submit the job script using:

```
sbatch job-script.sh
```

## Results

In the job's standard output file created on `/nfs/R-<JOB_NAME>.<JOB_ID>.out`, you shoud see some messages like:

```
Host <HOSTNAME>: rank 3 out of 4 processors
Host <HOSTNAME>: rank 0 out of 4 processors
Host <HOSTNAME>: rank 1 out of 4 processors
Host <HOSTNAME>: rank 2 out of 4 processors
```

For example:

```
$ cat R-mpi.50.out

Downloading the source code
Compiling the source code
Running the source code

Host aws-compute-1: rank 3 out of 4 processors
Host aws-compute-0: rank 0 out of 4 processors
Host aws-compute-0: rank 1 out of 4 processors
Host aws-compute-0: rank 2 out of 4 processors
```

Note that the rank's order may change, but the number of processors must be 4.
