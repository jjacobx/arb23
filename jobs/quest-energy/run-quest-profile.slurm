#!/bin/bash

#SBATCH --job-name=quest-profile
#SBATCH --time=01:30:00
#SBATCH --account=d35-ja
#SBATCH --qos=standard

#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=128

#SBATCH --error=out.profile/run-%j.err
#SBATCH --output=out.profile/run-%j.out
#SBATCH --partition=standard

module load arm/forge

export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK

: ${OMP_NUM_THREADS=128}
export OMP_NUM_THREADS=${OMP_NUM_THREADS}
export OMP_PLACES=cores

# Print job environment
echo "Job environment: "
echo "SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "SLURM_JOB_NAME=${SLURM_JOB_NAME}"
echo "SLURM_JOB_NUM_NODES=${SLURM_JOB_NUM_NODES}"
echo "SLURM_NTASKS=${SLURM_NTASKS}"
echo "SLURM_CPU_FREQ_REQ=${SLURM_CPU_FREQ_REQ}"
echo "OMP_NUM_THREADS=${OMP_NUM_THREADS}"
echo

# If not set by sbatch, set the following
: ${PROG=rand}
: ${QREG_SIZE=24}
: ${BLOCKING_QUBITS=32}
: ${QFT_METHOD=standard}
: ${DEPTH=16}
: ${TARGET_IDX=0}
: ${TARGET_IDX_1=0}
: ${TARGET_IDX_2=1}
: ${NGATES=100}

# Print program environment
echo "Program environment: "
echo "PROG=${PROG}"
echo "QREG_SIZE=${QREG_SIZE}"

# Set profiler output file
MAP_OUT="map.exp2/run-${SLURM_JOB_ID}_${PROG}_${SLURM_JOB_NUM_NODES}n_${QREG_SIZE}q_${SLURM_CPU_FREQ_REQ}"

# Set executable with arguments
DIR=../../build
if [ ${PROG} == "qft" ]; then
    echo "BLOCKING_QUBITS=${BLOCKING_QUBITS}"
    echo "QFT_METHOD=${QFT_METHOD}"
    EXE="${DIR}/${PROG} -q ${QREG_SIZE} -b ${BLOCKING_QUBITS} -m ${QFT_METHOD}"
elif [ ${PROG} == "rand" ]; then
    echo "DEPTH=${DEPTH}"
    EXE="${DIR}/${PROG} -q ${QREG_SIZE} -d ${DEPTH}"
elif [ ${PROG} == "hbench" ]; then
    echo "TARGET_IDX=${TARGET_IDX}"
    echo "NGATES=${NGATES}"
    EXE="${DIR}/${PROG} -q ${QREG_SIZE} -t ${TARGET_IDX} -n ${NGATES}"
elif [ ${PROG} == "swapbench" ]; then
    echo "TARGET_IDX_1=${TARGET_IDX_1}"
    echo "TARGET_IDX_2=${TARGET_IDX_2}"
    echo "NGATES=${NGATES}"
    EXE="${DIR}/${PROG} -q ${QREG_SIZE} -t1 ${TARGET_IDX_1} -t2 ${TARGET_IDX_2} -n ${NGATES}"
else
    echo "Unrecognised program ${PROG}!" 1>&2
    exit 1
fi

# Run executable in parallel
# --mpiargs="-Q --hint=nomultithread"
echo "Running ${EXE}: "
map -n ${SLURM_NPROCS} -o "${MAP_OUT}.map"  --profile ${EXE}


# Wait for energy results
sleep 10
echo

# Display energy results
sacct -j $SLURM_JOB_ID.0 --format=JobID,Elapsed,ConsumedEnergy


# Generate performance report
perf-report -o "${MAP_OUT}.html" "${MAP_OUT}.map"
perf-report -o "${MAP_OUT}.csv" "${MAP_OUT}.map"
