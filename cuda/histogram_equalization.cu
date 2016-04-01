#include <cuda.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
extern "C" {
    #include "jpegreadwrite.h"
}

static const int NUM_BINS = 256;

__global__ void histogram(unsigned char *data, unsigned int *buf, int size, int NUM_PARTS) {

    // Pixel coordinates
    int x = (blockIdx.x * blockDim.x) + threadIdx.x;
    int y = (blockIdx.y * blockDim.y) + threadIdx.y;

    // Linear thread index within a block
    int t = threadIdx.x + (threadIdx.y * blockDim.x); 

    // Linear block index within a grid
    int b = blockIdx.x + (blockIdx.y * gridDim.x);

    // Absolute linear thread index
    int i = x + (y * blockDim.x * gridDim.x);

    // Initialize temporary accumulation array in global memory
    unsigned int *my_buf = buf + (b * NUM_BINS);
    my_buf[t] = 0;

    // Count NUM_PARTS elements per thread for histogram
    int step = (int)ceil((float)size / (float)NUM_PARTS);
    if (i < step) {
        for (int p = 0; p < NUM_PARTS; p++) {
            int idx = i + (p * step);
            if (idx < size) {
                atomicAdd(&my_buf[data[idx]], 1);
            }
        }
    }
}

__global__ void accumulate(unsigned int *buf, int NUM_BLOCKS) {

    int i = threadIdx.x;
    unsigned int total = 0;

    // Accumulate partial histograms into single histogram
    for (int j = 0; j < NUM_BLOCKS; j++) {
        total += buf[i + (j * NUM_BINS)];
    }
    __syncthreads();

    buf[i] = total;

}

__global__ void equalize(unsigned int *buf, int size, int cdf_min) {

    // Absolute linear thread index
    int i = threadIdx.x;

    // Equalize
    buf[i] = round((float)(NUM_BINS - 1) * (buf[i] - cdf_min) / (size - cdf_min));

}

__global__ void update(unsigned char *data, unsigned int *buf, int size) {

    // Pixel coordinates
    int x = (blockIdx.x * blockDim.x) + threadIdx.x;
    int y = (blockIdx.y * blockDim.y) + threadIdx.y;

    // Absolute linear thread index
    int i = x + (y * blockDim.x * gridDim.x);

    if (i < size) {
        data[i] = (unsigned char)buf[data[i]];
    }
    
}

int scan(unsigned int *buf) {

    // Scan buffer to compute cumulative distribution function (cdf)
    int cdf_min = 0;

    for(int i = 1; i < NUM_BINS; i++) {

        buf[i] += buf[i - 1];

        if ((cdf_min == 0) && (buf[i] > 0)) {
            cdf_min = buf[i];
        }
    }

    return(cdf_min);

}

void my_print(unsigned char *data, int rows, int cols) {

    for(int n = 0; n < 10; n++) {
        for(int m = 0; m < 10; m++) {
            printf("%4hhu", data[m + (n * cols)]);
        }
        printf("\n");
    }
    printf("\n");
}

int test(void) {

    int rows = 4320;
    int cols = 7680;
    int size = rows * cols;

    int NUM_PARTS = 32;
    int NUM_BLOCKS = (int)ceil((float)size / (float)(NUM_BINS * NUM_PARTS));
    dim3 UPDATE_GRID(ceil(sqrt(NUM_BLOCKS * NUM_PARTS)), ceil(sqrt(NUM_BLOCKS * NUM_PARTS)));

    unsigned char *h_data;
    unsigned int *h_buf;
    h_data = (unsigned char *)malloc(size * sizeof *h_data);
    h_buf = (unsigned int*)malloc(NUM_BINS * sizeof *h_buf);

    unsigned char *d_data;
    unsigned int *d_buf;
    cudaMalloc(&d_data, size * sizeof *d_data);
    cudaMalloc(&d_buf, NUM_BINS * NUM_BLOCKS * sizeof *d_buf);

    // unsigned int *h_buf_test;
    // h_buf_test = (unsigned int *)malloc(NUM_BINS * sizeof *h_buf_test);

    // for (int i = 0; i < NUM_BINS; i++) {
    //     h_buf_test[i] = 0;
    // }

    for (int i = 0; i < size; i++) {
        h_data[i] = (unsigned char)((rand() % 75) + 150);
        // h_buf_test[h_data[i]] += 1;
    }

    my_print(h_data, rows, cols);

    cudaMemcpy(d_data, h_data, size * sizeof *h_data, cudaMemcpyHostToDevice);

    float time;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);

    histogram<<<NUM_BLOCKS, NUM_BINS>>>(d_data, d_buf, size, NUM_PARTS);
    accumulate<<<1, NUM_BINS>>>(d_buf, NUM_BLOCKS);

    cudaMemcpy(h_buf, d_buf, NUM_BINS * sizeof *d_buf, cudaMemcpyDeviceToHost);
    int cdf_min = scan(h_buf);
    cudaMemcpy(d_buf, h_buf, NUM_BINS * sizeof *h_buf, cudaMemcpyHostToDevice);

    equalize<<<1, NUM_BINS>>>(d_buf, size, cdf_min);
    update<<<UPDATE_GRID, NUM_BINS>>>(d_data, d_buf, size);

    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&time, start, stop);

    cudaMemcpy(h_data, d_data, size * sizeof *h_data, cudaMemcpyDeviceToHost);
    // cudaMemcpy(h_buf, d_buf, NUM_BINS * sizeof *h_buf, cudaMemcpyDeviceToHost);

    // for (int i = 0; i < NUM_BINS; i++) {
    //     unsigned int total = 0;
    //     for (int j = 0; j < NUM_BLOCKS; j++) {
    //         total += h_buf[i + (j * NUM_BINS)];
    //     }
    //     h_buf[i] = total;
    // }

    my_print(h_data, rows, cols);

    // for (int i = 0; i < NUM_BINS; i++) {
    //     printf("%4d, %5u, %5u, %5u\n", i, h_buf[i], h_buf_test[i], h_buf[i] - h_buf_test[i]);
    // }

    // printf("%d\n", cdf_min);
    // printf("%f\n", time);

    cudaFree(d_data);
    cudaFree(d_buf);
    free(h_data);
    free(h_buf);

    return(0);

}

int main(int argc, char **argv) {

    if(argc < 2) {
        fprintf(stderr, "Need jpeg file\n");
        return(-1);
    }

    char *filename = argv[1];

    // Read jpeg
    struct Image img;
    jpegread(filename, &img);

    int rows = img.height;
    int cols = img.width;
    int size = rows * cols;

    int NUM_PARTS = 256;
    int NUM_BLOCKS = (int)ceil((float)size / (float)(NUM_BINS * NUM_PARTS));
    dim3 UPDATE_GRID(ceil(sqrt(NUM_BLOCKS * NUM_PARTS)), ceil(sqrt(NUM_BLOCKS * NUM_PARTS)));

    unsigned char *h_data;
    unsigned int *h_buf;
    h_data = (unsigned char *)malloc(size * sizeof *h_data);
    h_buf = (unsigned int *)malloc(NUM_BINS * sizeof *h_buf);

    unsigned char *d_data;
    unsigned int *d_buf;
    cudaMalloc(&d_data, size * sizeof *d_data);
    cudaMalloc(&d_buf, NUM_BINS * NUM_BLOCKS * sizeof *d_buf);

    // Get Y component
    for(int j = 0; j < rows; j++) {
        for(int i = 0; i < cols; i++) {
            int offset = (j * cols * 3) + (i * 3);
            h_data[i + (j * cols)] = (unsigned char)img.buffer[offset];
        }
    }

    // my_print(h_data, rows, cols);

    cudaMemcpy(d_data, h_data, size * sizeof *h_data, cudaMemcpyHostToDevice);

    float time;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);

    histogram<<<NUM_BLOCKS, NUM_BINS>>>(d_data, d_buf, size, NUM_PARTS);
    accumulate<<<1, NUM_BINS>>>(d_buf, NUM_BLOCKS);

    cudaMemcpy(h_buf, d_buf, NUM_BINS * sizeof *d_buf, cudaMemcpyDeviceToHost);
    int cdf_min = scan(h_buf);
    cudaMemcpy(d_buf, h_buf, NUM_BINS * sizeof *h_buf, cudaMemcpyHostToDevice);

    equalize<<<1, NUM_BINS>>>(d_buf, size, cdf_min);
    update<<<UPDATE_GRID, NUM_BINS>>>(d_data, d_buf, size);

    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&time, start, stop);

    cudaMemcpy(h_data, d_data, size * sizeof *h_data, cudaMemcpyDeviceToHost);

    // my_print(h_data, rows, cols);

    printf("%f\n", time);

    // Update Y component
    for(int j = 0; j < rows; j++) {
        for(int i = 0; i < cols; i++) {
            int offset = (j * cols * 3) + (i * 3);
            img.buffer[offset] = h_data[i + (j * cols)];
        }
    }

    // Write jpeg
    jpegwrite("out.jpg", &img, 100);

}
