#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <jpeglib.h>
#include "jpegreadwrite.h"

void jpegread(const char* filename, struct Image* image) {

    // Open file
    FILE *infile = fopen(filename, "rb");
    if (infile == NULL) {
        fprintf(stderr, "Can't open %s\n", filename);
        exit(-1);
    }

    // Initialize info object
    struct jpeg_error_mgr err_pub;
    struct jpeg_decompress_struct cinfo;
    cinfo.err = jpeg_std_error(&err_pub);
    jpeg_create_decompress(&cinfo);

    // Set input file and read header
    jpeg_stdio_src(&cinfo, infile); 
    jpeg_read_header(&cinfo, TRUE);

    // Set read format
    cinfo.out_color_space = JCS_YCbCr;

    // Start decompression
    jpeg_start_decompress(&cinfo);

    // Setup buffer
    int row_stride = cinfo.output_width * cinfo.output_components;
    int buffer_size = row_stride * cinfo.output_height;
    image->buffer = malloc(buffer_size * sizeof *image->buffer);
    JSAMPARRAY line = (*cinfo.mem->alloc_sarray)((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);
    image->width = cinfo.output_width;
    image->height = cinfo.output_height;

    // Read each line
    while (cinfo.output_scanline < cinfo.output_height) {
        unsigned char *out_ptr = image->buffer + (cinfo.output_scanline * row_stride);
        jpeg_read_scanlines(&cinfo, line, 1);
        memcpy(out_ptr, line[0], row_stride);
    }

    // Clean up
    jpeg_finish_decompress(&cinfo);
    jpeg_destroy_decompress(&cinfo);
    fclose(infile);
  
}

void jpegwrite(const char* filename, struct Image* image, int quality) {

    // Open file
    FILE* outfile = fopen(filename, "wb");
    if (outfile == NULL) {
        fprintf(stderr, "Can't open %s\n", filename);
        exit(-1);
    }

    // Initialize info object
    struct jpeg_error_mgr err_pub;
    struct jpeg_compress_struct cinfo;
    cinfo.err = jpeg_std_error(&err_pub);
    jpeg_create_compress(&cinfo);

    // Set output file and write header
    jpeg_stdio_dest(&cinfo, outfile);
    cinfo.image_width = image->width; 
    cinfo.image_height = image->height;
    cinfo.input_components = 3;
    cinfo.in_color_space = JCS_YCbCr; 
    jpeg_set_defaults(&cinfo);
    jpeg_set_quality(&cinfo, quality, TRUE);
    jpeg_start_compress(&cinfo, TRUE);

    // Write each row
    JSAMPROW row_pointer[1];
    int row_stride = image->width * 3;
    while (cinfo.next_scanline < cinfo.image_height) {
        row_pointer[0] = &image->buffer[cinfo.next_scanline * row_stride];
        jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }

    // Cleanup
    jpeg_finish_compress(&cinfo);
    jpeg_destroy_compress(&cinfo);
    fclose(outfile);

}
