# High Performance Simulations of Quantum Circuits

This repository contains the files developed as a part of the PhD project *Benchmarking Quantum Advantage*. The idea behind it is to perform high performance simulations of quantum computers, which can be achieved with two general approaches: **statevector evolution** and **tensor network contraction**. The former approach stores and evolves a raw quantum state, while the latter is more flexible and can allow compression or truncation at the cost of precision. 

A large part of the project involves implementation and evaluation of various simulation strategies, focusing on characteristics like runtime, memory footprint, parallelism, accuracy and energy efficiency. The development is done on ARCHER2 and Cirrus hardware, with aid of various software toolkits, such as QuEST, Qiskit, or ITensor. Ultimately, I aim to build a comprehensive and portable framework, which can run effective high performance simulations of quantum computers that are still practical in the contemporary setting. The framework will be particularly useful for modelling quantum processing unit integration as an HPC accelerator. 

## Statevector Simulations

Performed using [QuEST] and [Qiskit] toolkits. 


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
* `-l`: enable 64-bit MPI messages (seems broken on ARCHER2)
* `-p`: enable profiling
* `-b`: enable non-blocking communications

Available targets: 
* `qft`: [quantum Fourier transform (QFT)][qft] implemented using 3 methods (*standard*/*built-in*/*cache-blocking*)
* `rand`: a circuit inspired by [Google's random circuit sampling (RCS)][rcs], but simplified to one-dimensional gates
* `hbench`: a benchmark of $`n`$ Hadamard gates on a single target qubit $`t`$
* `swapbench`: a benchmark of $`n`$ SWAP gates between qubits $`t_1`$ and $`t_2`$

You can create new targets by defining `circuits/<circuit-name>.cpp` files that specify new circuits. 

To run the built circuits, there are two SLURM scripts in `/jobs/quest-energy`: 
* `run-quest-energy.slurm`: default run
* `run-quest-profile.slurm`: run with profiling enabled

To automate experiments, create a file `submit-<experiment-name>.sh` in `/jobs/quest-energy`. A few examples are already provided. 


### Qiskit

Qiskit circuits are in the `qiskit/` directory. 



## Tensor Network Simulations

Performed using [ITensor][itensor] framework. 

Circuits available in the `itensor-projects/` directory



[quest]:        https://github.com/QuEST-Kit/QuEST
[qiskit]:       https://github.com/Qiskit/qiskit-aer
[qft]:          https://learn.qiskit.org/course/ch-algorithms/quantum-fourier-transform
[rcs]:          https://www.nature.com/articles/s41586%20019%201666%205
[itensor]:      https://github.com/ITensor/ITensor
