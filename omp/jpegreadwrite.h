#ifndef _JPEGREADWRITE_H_
#define _JPEGREADWRITE_H_

struct Image {
    int width;
    int height;
    unsigned char *buffer;
};

void jpegread(const char* filename, struct Image* image);
void jpegwrite(const char* filename, struct Image* image, int quality);

#endif
