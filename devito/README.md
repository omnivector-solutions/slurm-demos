# Seismic Applications with Devito

[Devito](https://www.devitoproject.org/) is a DSL (Domain-specific language) that implements optimized stencil computation (e.g., finite differences method) from high-level symbolic definitions. It is developed in Python and employs automated C/C++ code generation and just-in-time compilation to execute computational kernels on several computer platforms.

Devito is widely used to implement wave propagation kernels for use in seismic inversion problems, like FWI (Full waveform inversion). See below how to run some Devito's examples on a cluster.

A full list of seismic tutorials using Devito can be found in [Devito's GitHub repository](https://github.com/devitocodes/devito/tree/master/examples/seismic/tutorials).

- [Devito's Singularity Image](singularity_image)
- [Acoustic Wave Propagation](acoustic_wave_propagation)
- [Full Waveform Inversion (FWI)](fwi)
