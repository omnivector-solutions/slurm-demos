#!/bin/bash


set -eux


# Get the values to use to submit the job via slurmrestd
slurmctld_unit=`juju status --format=json | jq -r '.applications.slurmctld.units | keys[]'`

token=`juju run --unit $slurmctld_unit -- scontrol token username=ubuntu | awk -FSLURM_JWT= '{print $2}'`

slurmrestd_ip=`juju status --format=json | jq -r '.applications.slurmrestd.units[] | ."public-address"'`

slurmrestd_request_url="http://$slurmrestd_ip:6820/slurm/v0.0.36/job/submit"

python3 ./submit-job.py ubuntu $token $slurmrestd_request_url