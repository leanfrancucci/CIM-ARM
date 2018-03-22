///////////////////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////////////////

#define CCONV _stdcall
#define NOMANGLE extern "C" _declspec (dllexport)

CCONV int ConnectDatabase(char *ServerName, char *DbName, char *UserName, char *Password);

CCONV int CreateDatabase(char *ServerName, char *DbName, char *UserName, char *Password, short WriteMode, int Dialect);

CCONV int DisConnectDatabase();

CCONV int ExecuteStatement(char *ddlCommand);

CCONV int ExecuteBatch(char *ddlCommand);

CCONV int ExecuteSelect(char *dmlCommand, char *buffer, int *retlen);

CCONV char* ExecuteSelect2(char *dmlCommand, int *retlen, int withmeta);

CCONV int Check( short iVal );

CCONV void About();

CCONV void  Help();

CCONV void SetDebug(int setdebug);

CCONV void SetPageBuffers(short pb);

CCONV char* getPrimaryKeys(char *tablename);

CCONV char* getMetaData(char *tablename);

CCONV int StartTransaction(void);

CCONV int CommitTransaction(void);

CCONV int RollbackTransaction(void);

CCONV int ExecuteInTransaction(char *ddlCommand);

