# Energy Efficiency of Quantum Statevector Simulation at Scale

This repository contains the resources used in making the paper by J. Adamski, J. Richings and O. T. Brown submitted to the [SC Sustainable Supercomputing workshop][sc-workshop]. 

## Abstract

Classical simulations are essential for the development of quantum computing, and their exponential scaling can easily fill any modern supercomputer. In this paper we consider the performance and energy consumption of large Quantum Fourier Transform (QFT) simulations run on ARCHER2, the UK's National Supercomputing Service, with QuEST toolkit. We take into account CPU clock frequency and node memory size, and use cache-blocking to rearrange the circuit, which minimises communications. We find that using 2.00 GHz instead of 2.25 GHz can save as much as 25% of energy at 5% increase in runtime. Higher node memory also has the potential to be more efficient, and cost the user fewer CUs, but at higher runtime penalty. Finally, we present a cache-blocking QFT circuit, which halves the required communication. All our optimisations combined result in 40% faster simulations and 35% energy savings in 44 qubit simulations on 4,096 ARCHER2 nodes. 

## Statevector Simulations

Performed using [QuEST] toolkit. 


### QuEST

QuEST circuits are in the `circuits/` directory. 
Compile them with the following commands: 
```
./build.sh -t <circuit-name>
cd build
make
```

Additional arguments to `build.sh`:
* `-d <path>`: build in a different directory
* `-p`: enable profiling
* `-b`: enable non-blocking communications

Available targets: 
* `qft`: [quantum Fourier transform (QFT)][qft] implemented using 3 methods (*standard*/*built-in*/*cache-blocking*)
* `hbench`: a benchmark of $`n`$ Hadamard gates on a single target qubit $`t`$
* `swapbench`: a benchmark of $`n`$ SWAP gates between qubits $`t_1`$ and $`t_2`$

You can create new targets by defining `circuits/<circuit-name>.cpp` files that specify new circuits. 

To run the built circuits, there are two SLURM scripts in `/jobs/quest-energy`: 
* `run-quest-energy.slurm`: default run
* `run-quest-profile.slurm`: run with profiling enabled

To automate experiments, create a file `submit-<experiment-name>.sh` in `/jobs/quest-energy`. A few examples are already provided. 

[sc-workshop]:  https://sites.google.com/view/sc23sustainablescworkshop/home
[quest]:        https://github.com/QuEST-Kit/QuEST
[qft]:          https://learn.qiskit.org/course/ch-algorithms/quantum-fourier-transform
