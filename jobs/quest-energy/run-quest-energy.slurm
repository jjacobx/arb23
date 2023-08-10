#!/bin/bash

#SBATCH --job-name=quest-energy
#SBATCH --time=01:00:00
#SBATCH --account=d35-ja
#SBATCH --qos=standard

#SBATCH --hint=nomultithread
#SBATCH --distribution=block:block

#SBATCH --error=out/run-%j.err
#SBATCH --output=out/run-%j.out
#SBATCH --partition=standard

# Default 1 task per node
: ${CPUS_PER_NODE=128}
: ${SLURM_NTASKS_PER_NODE=1}
SLURM_CPUS_PER_TASK=$((CPUS_PER_NODE / SLURM_NTASKS_PER_NODE))
export SRUN_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}

# Default 1 thread per CPU
: ${OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}}
export OMP_NUM_THREADS=${OMP_NUM_THREADS}
export OMP_PLACES=cores

# Print job environment
echo "Job environment: "
echo "SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "SLURM_JOB_NAME=${SLURM_JOB_NAME}"
echo "SLURM_JOB_NUM_NODES=${SLURM_JOB_NUM_NODES}"
echo "SLURM_NTASKS=${SLURM_NTASKS}"
echo "SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"
echo "SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "SLURM_CPU_FREQ_REQ=${SLURM_CPU_FREQ_REQ}"
echo "OMP_NUM_THREADS=${OMP_NUM_THREADS}"
echo


# If not set by sbatch, set the following
: ${PROG=rand}
: ${QREG_SIZE=24}
: ${BLOCKING_QUBITS=32}
: ${QFT_METHOD=standard}
: ${PIVOT=0}
: ${DEPTH=16}
: ${TARGET_IDX=0}
: ${TARGET_IDX_1=0}
: ${TARGET_IDX_2=1}
: ${NGATES=100}

# Print program environment
echo "Program environment: "
echo "PROG=${PROG}"
echo "QREG_SIZE=${QREG_SIZE}"

# Set executable with arguments
: ${BIN_DIR="../../build"}
if [ ${PROG} == "qft" ]; then
    echo "BLOCKING_QUBITS=${BLOCKING_QUBITS}"
    echo "QFT_METHOD=${QFT_METHOD}"
    EXE="${BIN_DIR}/${PROG} -q ${QREG_SIZE} -b ${BLOCKING_QUBITS} -m ${QFT_METHOD} -p ${PIVOT}"
elif [ ${PROG} == "rand" ]; then
    echo "DEPTH=${DEPTH}"
    EXE="${BIN_DIR}/${PROG} -q ${QREG_SIZE} -d ${DEPTH}"
elif [ ${PROG} == "hbench" ]; then
    echo "TARGET_IDX=${TARGET_IDX}"
    echo "NGATES=${NGATES}"
    EXE="${BIN_DIR}/${PROG} -q ${QREG_SIZE} -t ${TARGET_IDX} -n ${NGATES}"
elif [ ${PROG} == "swapbench" ]; then
    echo "TARGET_IDX_1=${TARGET_IDX_1}"
    echo "TARGET_IDX_2=${TARGET_IDX_2}"
    echo "NGATES=${NGATES}"
    EXE="${BIN_DIR}/${PROG} -q ${QREG_SIZE} -t1 ${TARGET_IDX_1} -t2 ${TARGET_IDX_2} -n ${NGATES}"
else
    echo "Unrecognised program ${PROG}!" 1>&2
    exit 1
fi

echo

# Run executable in parallel
echo "Running ${EXE}: "
srun -Q --hint=nomultithread ${EXE}

# Wait for energy results
sleep 10
echo

# Display energy results
sacct -j $SLURM_JOB_ID.0 --format=JobID,Elapsed,ConsumedEnergy
