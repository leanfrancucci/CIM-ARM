#ifndef ROP_UTIL_H
#define ROP_UTIL_H

#define ROP_INTEGER  1
#define ROP_STRING   2
#define ROP_CHAR		 3
#define ROP_DATETIME 4
#define ROP_MONEY    5
#define ROP_BOOL		 6
#define ROP_BCD			 9
#define ROP_AUTOINC 10

int mapDataType(char *type);

#endif
