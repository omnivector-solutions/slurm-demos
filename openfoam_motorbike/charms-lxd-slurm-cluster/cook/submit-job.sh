#!/bin/bash


set -eux


# Get the job-script
wget -O /tmp/slurm-lxd-demo/run-motorbike-parallel.sh \
https://raw.githubusercontent.com/omnivector-solutions/slurm-demos/main/openfoam_motorbike/charms-lxd-slurm-cluster/run-motorbike-parallel.sh

# Get the values to use to submit the job via slurmrestd
slurmctld_unit=`juju status --format=json | jq -r '.applications.slurmctld.units | keys[]'`

token=`juju run --unit $slurmctld_unit -- scontrol token username=ubuntu | tr -d "SLURM_JWT="`

slurmrestd_ip=`juju status --format=json | jq -r '.applications.slurmrestd.units[] | ."public-address"'`

slurmrestd_request_url="http://$slurmrestd_ip:6820/slurm/v0.0.36/job/submit"

job_script_as_string=`curl -s https://raw.githubusercontent.com/omnivector-solutions/slurm-demos/main/openfoam_motorbike/charms-lxd-slurm-cluster/run-motorbike-parallel.sh`

curl --location --request POST '$slurmrestd_request_url' \
--header 'X-SLURM-USER-TOKEN: $token' \
--header 'X-SLURM-USER-NAME: ubuntu' \
--header 'Content-Type: application/json' \
--data '{
    "script": "$job_script_as_string"
    "job": {
        "get_user_environment": "1",
        "current_working_directory": "/nfs",
        "time_limit": 1800,
        "requeue": true,
    }
}'
