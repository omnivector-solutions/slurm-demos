# Singularity image for Devito

Devito's Singularity image is available in [https://omnivector-public-assets.s3.us-west-2.amazonaws.com/singularity/devito.sif](https://omnivector-public-assets.s3.us-west-2.amazonaws.com/singularity/devito.sif).

You can download it usig `curl`, `wget` or any simular tool.

For example:

```
$ wget https://omnivector-public-assets.s3.us-west-2.amazonaws.com/singularity/devito.sif
```

## Building the Singularity image for Devito

If you prefer to build the image on your system, you can use the definition file available [here](devito.def) and build it with the following command:

```
$ singularity build -f devito.sif devito.def
```

## Using the Singularity image for Devito

Once you have the SIF file, you can run the container with:

```
$ singularity exec devito.sif <CMD>
```

For example:

```
$ singularity exec devito.sif pip show devito

Name: devito
Version: 4.7.1+106.g09d97bdb6
Summary: Finite Difference DSL for symbolic computation.
Home-page: http://www.devitoproject.org
Author: Imperial College London
Author-email: g.gorman@imperial.ac.uk
License: MIT
Location: /opt/devito
Requires: anytree, cached-property, cgen, click, codecov, codepy, distributed, flake8, multidict, nbval, numpy, pip, psutil, py-cpuinfo, pyrevolve, pytest, pytest-cov, pytest-runner, scipy, sympy
Required-by: 
```
