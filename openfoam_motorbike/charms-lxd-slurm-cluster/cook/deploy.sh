#!/bin/bash


set -eux

# clone the repositories
git clone https://github.com/omnivector-solutions/slurm-charms.git -b mpi_install
git clone https://github.com/omnivector-solutions/slurm-bundles.git


# Create the directory that will house shared files (fake nfs for containers)
mkdir -p /srv/slurm-lxd-demo
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
cd slurm-charms && make charms && cd ..

cd slurm-bundles
make resources

juju deploy ./slurm-core/bundle.yaml \
            --overlay ./slurm-core/clouds/lxd.yaml \
            --overlay ./slurm-core/series/focal.yaml \
            --overlay ./slurm-core/charms/local-development.yaml --force
juju add-unit slurmd

# Go back to where we started
cd ../
