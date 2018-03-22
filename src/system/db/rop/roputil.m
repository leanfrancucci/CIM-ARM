#include "roputil.h"
#include "util.h"
#include <string.h>

typedef struct {
	char *type;
	int  value;
} DataTypeMap;

static DataTypeMap map[] = {
	{"INTEGER", ROP_INTEGER },
	{"STRING",  ROP_STRING },
	{"CHAR",		ROP_CHAR },
	{"DATETIME", ROP_DATETIME },
	{"MONEY",		ROP_MONEY },
	{"BOOL",    ROP_BOOL },
	{"BCD",		  ROP_BCD },
	{"AUTOINC", ROP_AUTOINC}
};

int 
mapDataType(char *type)
{
	int i;
	
	for (i = 0; i < sizeOfArray(map); ++i) {
		if ( strcmp(type, map[i].type) == 0) return map[i].value ;
	}
	
	return 0;

}
