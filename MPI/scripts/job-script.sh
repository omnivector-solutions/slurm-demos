#!/bin/bash
#SBATCH -p aws
#SBATCH --nodes=2
#SBATCH --ntasks=4
#SBATCH -J mpi
#SBATCH --output=/nfs/R-%x.%j.out
#SBATCH --error=/nfs/R-%x.%j.err
#SBATCH --chdir=/nfs
#SBATCH -t 1:00:00

# donwload the code
echo "Downloading the source code"
curl -o mpi_test.c --location "https://omnivector-public-assets.s3.us-west-2.amazonaws.com/code/mpi_test.c"

# compile the code
echo "Compiling the source code"
mpicc -o mpi_test mpi_test.c

# run the code
echo "Running the source code"
srun --mpi=pmi2 ./mpi_test
