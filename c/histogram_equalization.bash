#!/bin/sh
#BSUB -J bradbury
#BSUB -o histogram_equalization_output.txt
#BSUB -e histogram_equalization_error.txt
#BSUB -n 1
#BSUB -q ht-10g
#BSUB cwd /home/bradbury.d/project/c/

work=/home/bradbury.d/project/c/
cd $work

for i in `seq 1 10`;
do
    ./histogram_equalization ../images/winter.jpg
done
