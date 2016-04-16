#!/bin/sh
#BSUB -J histogram_equalization_global
#BSUB -o histogram_equalization_global_output.txt
#BSUB -e histogram_equalization_global_error.txt
#BSUB -n 32
#BSUB -R span[ptile=32]
#BSUB -q par-gpu-2
#BSUB cwd /home/bradbury.d/project/cuda_global/

work=/home/bradbury.d/project/cuda_global/
cd $work

for i in `seq 1 100`
do
    ./histogram_equalization ../images/winter.jpg
done
