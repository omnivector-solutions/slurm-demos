#!/bin/bash


set -eux

slurmd_units=`juju status --format=json | jq -r '.applications | .slurmd | .units | keys[]'`

for node in $slurmd_units; do
	juju run-action $node singularity-install
	juju run-action $node mpi-install
	juju run-action $node node-configured
done
