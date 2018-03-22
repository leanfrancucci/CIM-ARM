#include "SQLUtils.h"

/**/
char *formatSQLDate(char *buf, datetime_t date)
{
  struct tm bt;
  gmtime_r(&date, &bt);
  sprintf(buf, "%04d-%02d-%02d", bt.tm_year+1900, bt.tm_mon+1, bt.tm_mday);
  return buf;
}

/**/
char *formatSQLDateTime(char *buf, datetime_t date)
{
  struct tm bt;
  //gmtime_r(&date, &bt);
  localtime_r(&date, &bt);
  sprintf(buf, "%04d-%02d-%02d %02d:%02d:%02d", bt.tm_year+1900, bt.tm_mon+1, bt.tm_mday,bt.tm_hour,bt.tm_min,bt.tm_sec);
  return buf;
} 
