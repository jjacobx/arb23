#!/bin/bash

OUT_DIR=had50
mkdir -p "${OUT_DIR}-bl"
mkdir -p "${OUT_DIR}-nb"

QREG_SIZE=38
LOCAL_QUBITS=32 # Assuming distributed run
MAX_TARGET=$((${QREG_SIZE} - 1))
NNODES="$((2 ** (${QREG_SIZE} - ${LOCAL_QUBITS})))"

TARGETS=$(seq 0 ${MAX_TARGET})
NGATES=50

for t in ${TARGETS[@]}; do
    echo "Submitting job for TARGET_IDX=${t}..."

    # Wait if too many jobs are running
    while [ $(squeue -u $USER -h | wc -l) -gt 50 ]; do
        sleep 1
    done

    OUTPUT="${OUT_DIR}-bl/run-%j.out"
    ERROR="${OUT_DIR}-bl/run-%j.err"
    JOB_NAME="had-t${t}b"
    sbatch \
        --job-name=${JOB_NAME} \
        --output=${OUTPUT} \
        --error=${ERROR} \
        --nodes=${NNODES} \
        --ntasks-per-node=1 \
        --export=BIN_DIR="../../build-bl",PROG=hbench,QREG_SIZE=${QREG_SIZE},TARGET_IDX=${t},NGATES=${NGATES},VERBOSE=1 \
        run-quest-energy.slurm

    OUTPUT="${OUT_DIR}-nb/run-%j.out"
    ERROR="${OUT_DIR}-nb/run-%j.err"
    JOB_NAME="had-t${t}n"
    sbatch \
        --job-name=${JOB_NAME} \
        --output=${OUTPUT} \
        --error=${ERROR} \
        --nodes=${NNODES} \
        --ntasks-per-node=1 \
        --export=BIN_DIR="../../build-nb",PROG=hbench,QREG_SIZE=${QREG_SIZE},TARGET_IDX=${t},NGATES=${NGATES},VERBOSE=1 \
        run-quest-energy.slurm
done
