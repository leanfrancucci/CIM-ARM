#ifndef SQL_UTILS_H
#define SQL_UTILS_H

#include "system/lang/all.h"
#include "system/util/all.h"

char *formatSQLDate(char *buf, datetime_t date);
char *formatSQLDateTime(char *buf, datetime_t date);

#endif

