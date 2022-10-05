#!/bin/bash


set -eux

sudo apt install paraview


cd /srv/slurm-lxd-demo/motorbike-par-Job-10/motorBike/
paraview
