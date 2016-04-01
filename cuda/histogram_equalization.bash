#!/bin/sh
#BSUB -J bradbury
#BSUB -o histogram_equalization_output.txt
#BSUB -e histogram_equalization_error.txt
#BSUB -n 32
#BSUB -R span[ptile=32]
#BSUB -q par-gpu-2
#BSUB cwd /home/bradbury.d/project/cuda/

work=/home/bradbury.d/project/cuda/
cd $work

for i in `seq 1 10`
do
    ./histogram_equalization ../images/winter.jpg
done
