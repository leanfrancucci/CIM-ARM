/**
 *	@file:unicodecvtr.h
 */


#ifndef __UNICODECVTR_H__
#define __UNICODECVTR_H__

typedef struct {
    const unsigned char unicode;
    const unsigned char lcdcode;
}EXMAPITEM;

#define EXMAPITEM_END {0x00,0x00} /** Must be equal*/

unsigned char unicode_process_char(unsigned char **c);
void unicode_process_string(const char *ps , char *os);

#endif
