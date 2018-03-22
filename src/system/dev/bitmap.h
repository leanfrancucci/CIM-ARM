#ifndef TPRINTER_BITMAP_H
#define TPRINTER_BITMAP_H

typedef struct {
	int width;
	int height;
	char *image;
    char flags;
} BITMAP;

#define BITMAP_INVERT 0x1

void bitmap_draw(unsigned long pointer, int device);


#endif
