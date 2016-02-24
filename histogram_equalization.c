#include <math.h>
#include <time.h>
#include <stdio.h>
#include <limits.h>
#include <stdlib.h>

void equalize(unsigned char *data, int size) {
    
    int N = UCHAR_MAX + 1;

    unsigned long *buf = calloc(N, sizeof *buf);

    // Compute histogram buffer
    for(int i = 0; i < size; i++) {
        buf[data[i]] += 1;
    }

    // Scan buffer to compute cumulative distribution function (cdf)
    for(int i = 1; i < N; i++) {
        buf[i] += buf[i - 1];
    }

    // Determine minimum nonzero value in cdf
    int j = 0;
    while(buf[j] == 0) {
        j++;
    }
    
    int cdf_min = buf[j];

    // Equalize cdf over [0, 255]
    for(int i = 0; i < N; i++) {
        buf[i] = round((N - 1) * (buf[i] - cdf_min) / (size - cdf_min));
    }

    // Update data with equalized values
    for(int i = 0; i < size; i++) {
        data[i] = (unsigned char)buf[data[i]];
    }
    
    free(buf);

}

void my_print(unsigned char *data, int rows, int cols) {

    for(int n = 0; n < rows; n++) {
        for(int m = 0; m < cols; m++) {
            printf("%4hhu", data[m + (n * cols)]);
        }
        printf("\n");
    }
    printf("\n");
}

void my_save(FILE *fid, unsigned char *data, int *rows, int *cols, int size) {

    if(rows) {
        fwrite(rows, sizeof *rows, 1, fid);
    }
    if(cols) {
        fwrite(cols, sizeof *cols, 1, fid);
    }

    fwrite(data, sizeof *data, size, fid);
}

int main(void) {

    int rows = 4320, cols = 7680;
    int size = rows * cols;

    unsigned char *data = malloc(size * sizeof *data);

    for(int i = 0; i < size; i++) {
        data[i] = (unsigned char)((rand() % 75) + 75); // Preallocate data to values in range [75, 150)
    }

    FILE *fid = fopen("result.bin", "wb+");

    // my_print(data, rows, cols);
    my_save(fid, data, &rows, &cols, size);

    clock_t start_t, end_t;
    start_t = clock();

    equalize(data, size);
    
    end_t = clock();

    // my_print(data, rows, cols);
    my_save(fid, data, NULL, NULL, size);

    printf("%f\n", (double)(end_t - start_t)/CLOCKS_PER_SEC);
    
    fclose(fid);
    free(data);

    return(0);

}
