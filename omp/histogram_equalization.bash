#!/bin/sh
#BSUB -J bradbury
#BSUB -o histogram_equalization_output.txt
#BSUB -e histogram_equalization_error.txt
#BSUB -n 1
#BSUB -q ht-10g
#BSUB cwd /home/bradbury.d/project/omp/

work=/home/bradbury.d/project/omp/
cd $work

for i in `seq 1 10`;
do
    for num_threads in `seq 1 32`;
    do
        export OMP_NUM_THREADS=$num_threads
        ./histogram_equalization ../images/winter.jpg
    done
done
