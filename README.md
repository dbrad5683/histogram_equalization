# histogram_equalization

### Current Implementations
Sequential - c/

OpenMP - omp/

Cuda - cuda/

### Build Instructions
Compile with make from within the corresponding directory.

### Single Run Instructions
Run with ./histogram_equalization image.jpg from within the corresponding directory. Specify any JPEG file. Produces out.jpg. For the OpenMP version, set the OMP_NUM_THREADS environment variable as desired before running.

### Batch Run Instructions
Submit histogram_equalization.bash to bsub from within the corresponding directory. This is how all timing measurements were made.

### Notes
If libjpeg is not available, comment out everything in main and call test() instead. This generates random data and outputs it into result.bin. Using MATLAB, run util/plot_results.m and supply the path to result.bin to view the output.

The cuda implementation version of test() does not output result.bin yet. This will be added.
  
Sample images and outputs are included in the images directory. NOTE: The only 8K UHD sample image is winter.jpg. This is what was used for all timing measurements.
