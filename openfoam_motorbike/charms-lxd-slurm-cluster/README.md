# Run the OpenFOAM motorBike on an LXD-deployed Slurm Cluster

Describe how to set up an LXD-deployed slurm cluster to run the OpenFOAM motorBike example. 

## Prerequisites

This tutorial has been tested on an Ubuntu host system.

Make sure you have LXD, Juju and Charmcraft installed and configured. 

You may install and configure them with the following commands:

1) LXD
```
# install LXD
sudo snap install lxd

# init and configure LXD
sudo lxd init --auto

# disable IPV6
sudo lxc network set lxdbr0 ipv6.address none
```

2) Juju
```
# install Juju client
sudo snap install juju --classic

# bootstrap a local LXD Juju controller
juju bootstrap localhost
```

3) Charmcraft
```
# install charmcraft
sudo snap install charmcraft --classic
```

## Steps to deploy the local slurm cluster

1) Clone and access the `omnivector-solutions/slurm-charms` repository:

```
# clone the repository
git clone https://github.com/omnivector-solutions/slurm-charms.git

# access the slurm-charms directory
cd slurm-charms

# checkout to mpi_install branch
git checkout mpi_install
```

2) Add the file [lxd-profile.yaml](lxd-profile.yaml) in `slurm-charms/charm-slurmd` directory:

```
# copy lxd-profile.yaml to slurm-charms/charm-slurmd
cp <PATH_TO/lxd-profile.yaml> charm-slurmd/
```

3) Add full permissions in the `source` directory, defined in `lxd-profile.yaml`. This directory in the host is going be shared between the slurmd containers (compute nodes) in the `/nfs` (inside the containers) path.

```
# this one is according to the example in the lxd-profile.yaml
# you can choose any directory in you host system to be shared
sudo chmod 777 /home/ubuntu/nfs-in-host
```
4) Still inside the `slurm-charms` directory, make the charms:

```
make charms
```

5) Exit the `slurm-charms` and go it's parent directory when the process completes:

```
cd ..
```

6) Clone and access the `omnivector-solutions/slurm-bundles` repository:

```
# clone the repository
git clone https://github.com/omnivector-solutions/slurm-bundles.git

# access the slurm-bundles directory
cd slurm-bundles
```

7) In `slurm-bundles` edit the `Makefile` to add `--force` at the end of:

```
.PHONY: lxd-focal
lxd-focal: ${ETCD} singularity ${NHC} ## Deploy slurm-core in a local LXD Ubuntu Focal cluster
	juju deploy ./slurm-core/bundle.yaml \
	            --overlay ./slurm-core/clouds/lxd.yaml \
	            --overlay ./slurm-core/series/focal.yaml \
	            --overlay ./slurm-core/charms/local-development.yaml
```
Changing it to:

```
.PHONY: lxd-focal
lxd-focal: ${ETCD} singularity ${NHC} ## Deploy slurm-core in a local LXD Ubuntu Focal cluster
	juju deploy ./slurm-core/bundle.yaml \
	            --overlay ./slurm-core/clouds/lxd.yaml \
	            --overlay ./slurm-core/series/focal.yaml \
	            --overlay ./slurm-core/charms/local-development.yaml --force
```

8) Deploy the LXD slurm cluster:

```
make lxd-focal
```

9) The deployment process may take a while to complete. You can see the status with:

```
watch -n 1 -c juju status --color
```
When the process is complete, you should see something similar to:

```
Model   Controller           Cloud/Region         Version  SLA          Timestamp
summit  localhost-localhost  localhost/localhost  2.9.34   unsupported  16:33:39-03:00

App              Version          Status  Scale  Charm            Channel  Rev  Exposed  Message
percona-cluster  5.7.20           active      1  percona-cluster  stable   293  no       Unit is ready
slurmctld        0.10.0-5-g93...  active      1  slurmctld                   0  no       slurmctld available
slurmd           0.10.0-5-g93...  active      2  slurmd                      0  no       slurmd available
slurmdbd         0.10.0-5-g93...  active      1  slurmdbd                    0  no       slurmdbd available
slurmrestd       0.10.0-5-g93...  active      1  slurmrestd                  0  no       slurmrestd available

Unit                Workload  Agent  Machine  Public address  Ports     Message
percona-cluster/0*  active    idle   0        10.40.221.79    3306/tcp  Unit is ready
slurmctld/0*        active    idle   1        10.40.221.229             slurmctld available
slurmd/0*           active    idle   2        10.40.221.156             slurmd available
slurmdbd/0*         active    idle   3        10.40.221.99              slurmdbd available
slurmrestd/0*       active    idle   4        10.40.221.177             slurmrestd available

Machine  State    Address        Inst id        Series  AZ  Message
0        started  10.40.221.79   juju-f3f622-0  bionic      Running
1        started  10.40.221.229  juju-f3f622-1  focal       Running
2        started  10.40.221.156  juju-f3f622-2  focal       Running
3        started  10.40.221.99   juju-f3f622-3  focal       Running
4        started  10.40.221.177  juju-f3f622-4  focal       Running
```

10) You can add another `slurmd` unit with:

```
juju add-unit slurmd
```

After that, the status should look like:

```
Model   Controller           Cloud/Region         Version  SLA          Timestamp
summit  localhost-localhost  localhost/localhost  2.9.34   unsupported  16:33:39-03:00

App              Version          Status  Scale  Charm            Channel  Rev  Exposed  Message
percona-cluster  5.7.20           active      1  percona-cluster  stable   293  no       Unit is ready
slurmctld        0.10.0-5-g93...  active      1  slurmctld                   0  no       slurmctld available
slurmd           0.10.0-5-g93...  active      2  slurmd                      0  no       slurmd available
slurmdbd         0.10.0-5-g93...  active      1  slurmdbd                    0  no       slurmdbd available
slurmrestd       0.10.0-5-g93...  active      1  slurmrestd                  0  no       slurmrestd available

Unit                Workload  Agent  Machine  Public address  Ports     Message
percona-cluster/0*  active    idle   0        10.40.221.79    3306/tcp  Unit is ready
slurmctld/0*        active    idle   1        10.40.221.229             slurmctld available
slurmd/0*           active    idle   2        10.40.221.156             slurmd available
slurmd/1            active    idle   5        10.40.221.78              slurmd available
slurmdbd/0*         active    idle   3        10.40.221.99              slurmdbd available
slurmrestd/0*       active    idle   4        10.40.221.177             slurmrestd available

Machine  State    Address        Inst id        Series  AZ  Message
0        started  10.40.221.79   juju-f3f622-0  bionic      Running
1        started  10.40.221.229  juju-f3f622-1  focal       Running
2        started  10.40.221.156  juju-f3f622-2  focal       Running
3        started  10.40.221.99   juju-f3f622-3  focal       Running
4        started  10.40.221.177  juju-f3f622-4  focal       Running
5        started  10.40.221.78   juju-f3f622-5  focal       Running
```

11) Install singularity in the `slurmd` units:

```
juju run-action slurmd/0 singularity-install
juju run-action slurmd/1 singularity-install
```

12) Install mpich in the `slurmd` units:

```
juju run-action slurmd/0 mpi-install
juju run-action slurmd/1 mpi-install
```

13) Set the compute nodes to idle and ready to compute jobs:

```
juju run-action slurmd/0 node-configured
juju run-action slurmd/1 node-configured
```

## Running the motorBike job:

1) Put the files [run-motorbike-sequential.sh](run-motorbike-sequential.sh) and [run-motorbike-parallel.sh](run-motorbike-parallel.sh) inside your source (as defined in [lxd-profile.yaml](lxd-profile.yaml)) directory in the host:

```
cp <PATH_TO/run-motorbike-sequential.sh> /home/ubuntu/nfs-in-host
cp <PATH_TO/run-motorbike-parallel.sh> /home/ubuntu/nfs-in-host
```

2) Access one of the `slurmd` units:

```
juju ssh slurmd/0
```

3) Inside the `slurmd` unit:

	3.1) Go to `/nfs` directory:

	```
	cd /nfs
	```

	3.2) Submit the job:

	```
	# sequential
	sbatch run-motorbike-sequential.sh

	# parallel
	sbatch run-motorbike-parallel.sh
	```

## Viewing the result in Paraview:

1) When the job completes, back in the host go to `/home/ubuntu/nfs-in-host` directory:

```
cd /home/ubuntu/nfs-in-host
```

2) You should see a list of files and folders, similar to:

```
$ ls
motorbike-par-Job-10  OpenFOAM-10  openfoam10-sandbox  openfoam10.sif  R-motorbike-par.10.err  R-motorbike-par.10.out  run-motorbike-parallel.sh  run-motorbike-sequential.sh
```

These two files has the job execution messages:

- The `R-<JOB_NAME>.<JOB_ID>.err` (`R-motorbike-par.10.err` in this tutorial) contains the job's standard error messages
- The `R-<JOB_NAME>.<JOB_ID>.out` (`R-motorbike-par.10.out` in this tutorial) contains the job's standard output messages

In the `<JOB_NAME>-Job-<JOB_ID>` folder (`motorbike-par-Job-10` in this tutorial) you should see the motorBike folder, which has the results.

3) Thus, go to `<JOB_NAME>-Job-<JOB_ID>/motorBike` directory:

```
cd motorbike-par-Job-10/motorBike/
```

4) The easiest way to visualize the motorBike's result mesh in Paraview is to have OpenFOAM installed in you host system. Follow the instructions in this [link](https://openfoam.org/download/10-ubuntu/) to install OpenFOAM v10 on Ubuntu.

	With OpenFOAM installed in your host system and from inside the `/home/ubuntu/nfs-in-host/<JOB_NAME>-Job-<JOB_ID>/motorBike` directory, run the `paraFoam` command, which will automatically open up the result in Paraview:
	```
	paraFoam
	```
	
	If you do not have OpenFOAM installed, but have Paraview, you must create a file inside `/home/ubuntu/nfs-in-host/<JOB_NAME>-Job-<JOB_ID>/motorBike` named `<ANY_FILE_NAME>.foam` (no content needed) and open it in Paraview, which will automatically identify the result files inside the folder and render them:
	```
	touch motorBike.foam
	```
	
