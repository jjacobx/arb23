#!/bin/bash

OUT_DIR=swap50
mkdir -p "${OUT_DIR}-bl"
mkdir -p "${OUT_DIR}-nb"

OUTPUT="${OUT_DIR}/run-%j.out"
ERROR="${OUT_DIR}/run-%j.err"


QREG_SIZE=38
LOCAL_QUBITS=32 # Assuming distributed run
MAX_TARGET=$((${QREG_SIZE} - 1))
NNODES="$((2 ** (${QREG_SIZE} - ${LOCAL_QUBITS})))"

TARGETS_1=$(seq 0 4 16)
TARGETS_2=$(seq 35 ${MAX_TARGET})
NGATES=50

for t1 in ${TARGETS_1[@]}; do
    for t2 in ${TARGETS_2[@]}; do
        echo "Submitting job for TARGET_IDX_1=${t1}, TARGET_IDX_2=${t2}..."

        # Wait if too many jobs are running
        while [ $(squeue -u $USER -h | wc -l) -gt 50 ]; do
            sleep 1
        done

        OUTPUT="${OUT_DIR}-bl/run-%j.out"
        ERROR="${OUT_DIR}-bl/run-%j.err"
        JOB_NAME="s-${t1}-${t2}b"
        sbatch \
            --job-name=${JOB_NAME} \
            --output=${OUTPUT} \
            --error=${ERROR} \
            --nodes=${NNODES} \
            --ntasks-per-node=1 \
            --export=BIN_DIR="../../build-bl",PROG=swapbench,QREG_SIZE=${QREG_SIZE},TARGET_IDX_1=${t1},TARGET_IDX_2=${t2},NGATES=${NGATES},VERBOSE=1 \
            run-quest-energy.slurm

        OUTPUT="${OUT_DIR}-nb/run-%j.out"
        ERROR="${OUT_DIR}-nb/run-%j.err"
        JOB_NAME="s-${t1}-${t2}n"
        sbatch \
            --job-name=${JOB_NAME} \
            --output=${OUTPUT} \
            --error=${ERROR} \
            --nodes=${NNODES} \
            --ntasks-per-node=1 \
            --export=BIN_DIR="../../build-nb",PROG=swapbench,QREG_SIZE=${QREG_SIZE},TARGET_IDX_1=${t1},TARGET_IDX_2=${t2},NGATES=${NGATES},VERBOSE=1 \
            run-quest-energy.slurm
    done
done
