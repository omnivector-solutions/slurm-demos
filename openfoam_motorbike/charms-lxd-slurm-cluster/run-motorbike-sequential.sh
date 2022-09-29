#!/bin/bash
#SBATCH -p osd-slurmd
#SBATCH --ntasks=1
#SBATCH -J motorbike-seq
#SBATCH --output=/nfs/R-%x.%j.out
#SBATCH --error=/nfs/R-%x.%j.err
#SBATCH -t 1:00:00

# clone OpenFOAM-10 if it is not available yet
OPENFOAM_DIR=/nfs/OpenFOAM-10
if [[ ! -d $OPENFOAM_DIR ]]
then
    echo "Cloning OpenFOAM-10"
    cd /nfs
    git clone https://github.com/OpenFOAM/OpenFOAM-10.git
else
    echo "Skipping clone process...we already have the OpenFOAM-10 source code"
fi

# path to the openfoam singularity image
SINGULARITY_IMAGE=/nfs/openfoam10.sif

# path to the openfoam singularity sandbox
SINGULARITY_SANDBOX=openfoam10-sandbox
SINGULARITY_SANDBOX_PATH=/nfs/$SINGULARITY_SANDBOX

# create the openfoam singularity sandbox if it is not available yet
if [[ ! -d $SINGULARITY_SANDBOX_PATH ]]
then    
    cd /nfs
    
    # download the openfoam v10 singularity image if it is not available yet
    if [[ ! -f $SINGULARITY_IMAGE ]]
    then
        echo "Fetching the singularity image for OpenFOAM-10"
        curl -o $SINGULARITY_IMAGE --location "https://omnivector-public-assets.s3.us-west-2.amazonaws.com/singularity/openfoam10.sif"        
    else
        echo "Skipping the image fetch process...we already have the singularity image"
    fi
    
    # build the singularity sandbox
    echo "Building OpenFOAM-10 singularity sandbox"
    singularity build --sandbox $SINGULARITY_SANDBOX $SINGULARITY_IMAGE
else
    echo "Skipping the sandbox building process...we already have the singularity sandbox"
fi

# create a working folder inside the shared directory
WORK_DIR=/nfs/$SLURM_JOB_NAME-Job-$SLURM_JOB_ID
mkdir -p $WORK_DIR
cd $WORK_DIR

# copy motorBike folder
cp -r $OPENFOAM_DIR/tutorials/incompressible/simpleFoam/motorBike .

# enter motorBike folder
cd motorBike

# clear any previous execution
singularity exec --bind $PWD:$HOME $SINGULARITY_SANDBOX_PATH ./Allclean

# copy motorBike geometry obj
cp $OPENFOAM_DIR/tutorials/resources/geometry/motorBike.obj.gz constant/geometry/

# define surface features inside the block mesh
singularity exec --bind $PWD:$HOME $SINGULARITY_SANDBOX_PATH surfaceFeatures

# generate the first mesh
# mesh the environment (block around the model)
singularity exec --bind $PWD:$HOME $SINGULARITY_SANDBOX_PATH blockMesh

# mesh the motorcicle
# overwrite the new mesh files that are generated
singularity exec --bind $PWD:$HOME $SINGULARITY_SANDBOX_PATH snappyHexMesh -overwrite

# write field and boundary condition info for each patch
singularity exec --bind $PWD:$HOME $SINGULARITY_SANDBOX_PATH patchSummary

# potential flow solver
# solves the velocity potential to calculate the volumetric face-flux field
singularity exec --bind $PWD:$HOME $SINGULARITY_SANDBOX_PATH potentialFoam

# steady-state solver for incompressible turbutent flows
singularity exec --bind $PWD:$HOME $SINGULARITY_SANDBOX_PATH simpleFoam

# create a .foam file to render the results in Paraview
touch motorbike.foam 
