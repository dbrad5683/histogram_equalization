histogram_equalization: histogram_equalization.c jpegreadwrite.c
	gcc histogram_equalization.c jpegreadwrite.c -o histogram_equalization -ljpeg

