#!/bin/bash
#SBATCH -p aws
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -J motorbike-seq
#SBATCH --output=/nfs/R-%x.%j.out
#SBATCH --error=/nfs/R-%x.%j.err
#SBATCH -t 1:00:00

# create a working folder inside the shared directory
WORK_DIR=/nfs/$SLURM_JOB_NAME-Job-$SLURM_JOB_ID
mkdir -p $WORK_DIR
cd $WORK_DIR

# download the openfoam v10 singularity image
curl -o openfoam10.sif --location "https://omnivector-public-assets.s3.us-west-2.amazonaws.com/singularity/openfoam10.sif"

# path to the openfoam singularity image
export SINGULARITY_IMAGE=$PWD/openfoam10.sif

# clone the OpenFOAM 10 tutorial repository
git clone https://github.com/OpenFOAM/OpenFOAM-10.git

# copy motorBike folder
cp -r OpenFOAM-10/tutorials/incompressible/simpleFoam/motorBike .

# enter motorBike folder
cd motorBike

# clear any previous execution
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE ./Allclean

# copy motorBike geometry obj
cp ../OpenFOAM-10/tutorials/resources/geometry/motorBike.obj.gz constant/geometry/

# define surface features inside the block mesh
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE surfaceFeatures

# generate the first mesh
# mesh the environment (block around the model)
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE blockMesh

# mesh the motorcicle
# overwrite the new mesh files that are generated
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE snappyHexMesh -overwrite

# write field and boundary condition info for each patch
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE patchSummary

# potential flow solver
# solves the velocity potential to calculate the volumetric face-flux field
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE potentialFoam

# steady-state solver for incompressible turbutent flows
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE simpleFoam
 
