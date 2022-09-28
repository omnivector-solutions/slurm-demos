#!/bin/bash
#SBATCH -p aws
#SBATCH --ntasks=1
#SBATCH -J wave_propagation
#SBATCH --output=/nfs/R-%x.%j.out
#SBATCH --error=/nfs/R-%x.%j.err
#SBATCH -t 1:00:00

# Devito's env variables
export DEVITO_LANGUAGE=openmp
export DEVITO_LOGGING=DEBUG
export DEVITO_ARCH=gcc

cd /nfs

# path to the devito singularity image
SINGULARITY_IMAGE=/nfs/devito.sif

# download the devito singularity image if it is not available yet
if [[ ! -f $SINGULARITY_IMAGE ]]
then
    echo "Fetching the singularity image for Devito"
    curl -o $SINGULARITY_IMAGE --location "https://omnivector-public-assets.s3.us-west-2.amazonaws.com/singularity/devito.sif"
else
    echo "Skipping the image fetch process...we already have the singularity image"
fi

# create a working folder inside the shared directory
WORK_DIR=/nfs/$SLURM_JOB_NAME-Job-$SLURM_JOB_ID
mkdir -p $WORK_DIR
cd $WORK_DIR

echo "Downloading the the application source code"
APP=acoustic_wave_propagation.py
curl -o $APP --location "https://omnivector-public-assets.s3.us-west-2.amazonaws.com/code/acoustic_wave_propagation.py"

# run the simulation
singularity exec --bind $PWD:$HOME $SINGULARITY_IMAGE python $APP
