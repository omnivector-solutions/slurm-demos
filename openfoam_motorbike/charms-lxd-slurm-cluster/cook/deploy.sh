#!/bin/bash


set -eux

# clone the repositories
if [[ ! -d slurm-charms ]]
then
  git clone https://github.com/omnivector-solutions/slurm-charms.git
fi
if [[ ! -d slurm-bundles ]]
then
  git clone https://github.com/omnivector-solutions/slurm-bundles.git
fi


# Create the directory that will house shared files (fake nfs for containers)
sudo mkdir -p /srv/slurm-lxd-demo
sudo chmod -R 777 /srv/slurm-lxd-demo

# Create the lxd-profile that will provide an shared storage and enabled privileged mode
cat > ./slurm-charms/charm-slurmd/lxd-profile.yaml <<EOY
config:
  security.privileged: "true"
description: ""
devices:
  shared:
    path: /nfs
    source: /srv/slurm-lxd-demo
    type: disk
name: shared
EOY

# Build the slurm-charms
cd slurm-charms
if [[ ! -f slurmctld.charm ]]
then
  make slurmctld
fi
if [[ ! -f slurmdbd.charm ]]
then
  make slurmdbd
fi
if [[ ! -f slurmd.charm ]]
then
  make slurmd
fi
if [[ ! -f slurmrestd.charm ]]
then
  make slurmrestd
fi
cd ..

cd slurm-bundles
make resources

juju deploy ./slurm-core/bundle.yaml \
            --overlay ./slurm-core/clouds/lxd.yaml \
            --overlay ./slurm-core/series/focal.yaml \
            --overlay ./slurm-core/charms/local-development.yaml --force

# add one more slurmd unit
juju add-unit slurmd

# Go back to where we started
cd ../
