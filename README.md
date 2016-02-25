# histogram_equalization

Compile
  $ make
Run with any JPEG file. Outputs equalized image to out.jpg
  $ ./histogram_equalization <image.jpg>
  
If libjpeg is not available, comment out everything in main and call test() instead.
  This generates random data and outputs it into result.bin. Using MATLAB, run
  histogram_equalization.m from the same directory as result.bin to view the output.
  
Sample images and outputs are included in the images directory.
  NOTE: The only 8K UHD sample image is winter.jpg
