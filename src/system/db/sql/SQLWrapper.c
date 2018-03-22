#include <stdio.h>
#include "SQLWrapper.h"
#include "fbwrapc.h"
#include "osrt.h"
#include "lang/all.h"

static Mutex_t sqlwrapper_mutex;

#define TAKE_MUTEX()			mutexLock( &sqlwrapper_mutex )
#define RELEASE_MUTEX()		mutexUnlock( &sqlwrapper_mutex )

//#define LOG_SQL 1
#undef LOG_SQL

static int isConnected = 0;

/**/
int sqlConnectDatabase(char *ServerName, char *DbName, char *UserName, char *Password)
{
  int connect = ConnectDatabase(ServerName, DbName, UserName, Password);
	mutexInit( &sqlwrapper_mutex, NULL );
  if (connect == 1) isConnected = 1;
  return connect;
}

/**/
int sqlCreateDatabase(char *ServerName, char *DbName, char *UserName, char *Password, short WriteMode, int Dialect)
{
	return CreateDatabase(ServerName, DbName, UserName, Password, WriteMode, Dialect);
}

/**/
int sqlDisconnectDatabase()
{
  if (isConnected)
	return DisConnectDatabase();
  return 0;
}

/**/
int sqlExecuteStatement(char *ddlCommand)
{
	int res;
#ifdef LOG_SQL	
  unsigned long ticks = getTicks();
#endif
  TAKE_MUTEX();
  res = ExecuteStatement(ddlCommand);

#ifdef LOG_SQL
 /* doLog(0,"----------------------------------------------------------------------------\n");
  doLog(0,"%s", ddlCommand);
  doLog(0,"Tardo %ld ms\n", getTicks() - ticks);
  doLog(0,"----------------------------------------------------------------------------\n");
  fflush(stdout); */
#endif
  
  RELEASE_MUTEX();
  return res;
}

/**/
char *sqlExecuteSelect(char *dmlCommand, int *retlen, int withMetadata)
{
	char *res;
#ifdef LOG_SQL
	unsigned long ticks = getTicks();
#endif
  TAKE_MUTEX();
  res = ExecuteSelect2(dmlCommand, retlen, withMetadata);
#ifdef LOG_SQL
 /* doLog(0,"----------------------------------------------------------------------------\n");
  doLog(0,"%s", dmlCommand);
  doLog(0,"Tardo %ld ms\n", getTicks() - ticks);
  doLog(0,"----------------------------------------------------------------------------\n");
  fflush(stdout);*/
#endif
  RELEASE_MUTEX();
  return res;
}

/**/
void sqlSetDebug(int setdebug)
{
	 SetDebug(setdebug);
}

/**/
void sqlSetPageBuffers(short pb)
{
	SetPageBuffers(pb);
}

/**/
char *sqlGetPrimaryKeys(char *tableName)
{
	char* res;
  TAKE_MUTEX();
  res = getPrimaryKeys(tableName);
  RELEASE_MUTEX();
  return res;
}

/**/
char *sqlGetMetaData(char *tableName)
{
  char* res;
  TAKE_MUTEX();
  res = getMetaData(tableName);
  RELEASE_MUTEX();
  return res;
}

/**/
int sqlStartTransaction(void)
{
  int res;
  TAKE_MUTEX();
  res = StartTransaction();
  RELEASE_MUTEX();
  return res;
}

/**/
int sqlCommitTransaction(void)
{
  int res;
  TAKE_MUTEX();
  res = CommitTransaction();
  RELEASE_MUTEX();
  return res;
}

/**/
int sqlRollbackTransaction(void)
{
  int res;
  TAKE_MUTEX();
  res = RollbackTransaction();
  RELEASE_MUTEX();
  return res;
}

/**/
int sqlExecuteInTransaction(char *ddlCommand)
{
  int res;
  TAKE_MUTEX();
  res = ExecuteInTransaction(ddlCommand);
  RELEASE_MUTEX();
  return res;
}

