#!/bin/bash
#SBATCH -p aws
#SBATCH --nodes=2
#SBATCH --ntasks=6
#SBATCH -J motorbike
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

# decomposition of mesh and initial field data
# according to the parameters in decomposeParDict located in the system
# create 6 domains by default
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE decomposePar -copyZero

# mesh the motorcicle
# overwrite the new mesh files that are generated
srun singularity exec --bind $PWD:/root $SINGULARITY_IMAGE snappyHexMesh -overwrite -parallel

# write field and boundary condition info for each patch
srun singularity exec --bind $PWD:/root $SINGULARITY_IMAGE patchSummary -parallel

# potential flow solver
# solves the velocity potential to calculate the volumetric face-flux field
srun singularity exec --bind $PWD:/root $SINGULARITY_IMAGE potentialFoam -parallel

# steady-state solver for incompressible turbutent flows
srun singularity exec --bind $PWD:/root $SINGULARITY_IMAGE simpleFoam -parallel

# after a case has been run in parallel
# it can be reconstructed for post-processing
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE reconstructParMesh -constant
singularity exec --bind $PWD:/root $SINGULARITY_IMAGE reconstructPar -latestTime
 
