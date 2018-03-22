#ifndef SQL_FIELD_H
#define SQL_FIELD_H

#include "SQLTypes.h"
#include "system/lang/all.h"

typedef struct {
	char	fieldName[255];
	int		fieldSize;
	int		fieldOffset;
	SQLType fieldType;
	int		fieldScale;
	int		fieldIsPK;
} SQLField;

#endif
