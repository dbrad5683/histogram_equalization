#!/bin/sh
#BSUB -J histogram_equalization_shared
#BSUB -o histogram_equalization_shared_output.txt
#BSUB -e histogram_equalization_shared_error.txt
#BSUB -n 32
#BSUB -R span[ptile=32]
#BSUB -q par-gpu-2
#BSUB cwd /home/bradbury.d/project/cuda_shared/

work=/home/bradbury.d/project/cuda_shared/
cd $work

for n in `seq 1 10`
do
    for i in `seq 1 100`
    do
        ./histogram_equalization ./winter.jpg $((2**$n))
    done
done
