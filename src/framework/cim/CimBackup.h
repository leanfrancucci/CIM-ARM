#ifndef CIM_BACKUP_H
#define CIM_BACKUP_H

#define CIM_BACKUP id

#include <Object.h>
#include "ctapp.h"
#include "system/os/all.h"
#include "system/util/all.h"
#include "system/db/all.h"

#define INIT_FILES_PATH       BASE_APP_PATH "/initFiles/"
#define COPY_FILES_PATH				BASE_APP_PATH "/copyFiles/"
#define DUMP_FILES_PATH				BASE_VAR_PATH "/data"
#define DUMP_BCK_FILES_PATH		BASE_APP_PATH "/dumpBackup/"
#define DATA_FILES_PATH				BASE_APP_PATH "/data/"

/**
 *	Especifica el tipo de backup a efectuar
 */
typedef enum {
	BackupType_UNDEFINED,
	BackupType_ALL,						/** all tables: TRANSACTIONS / SETTINGS / USERS */
	BackupType_TRANSACTIONS,	/** only TRANSACTIONS */
	BackupType_SETTINGS,			/** only SETTINGS */
	BackupType_USERS					/** only USERS */
} BackupType;

/**
 *	Especifica el tipo de restore a efectuar
 */
typedef enum {
	RestoreType_UNDEFINED,
	RestoreType_ALL,						/** all tables: TRANSACTIONS / SETTINGS / USERS */
	RestoreType_TRANSACTIONS,	/** only TRANSACTIONS */
	RestoreType_SETTINGS,			/** only SETTINGS */
	RestoreType_USERS					/** only USERS */
} RestoreType;

/**
 *	doc template
 *	<<singleton>>
 */
@interface CimBackup : OThread
{
	SYNC_QUEUE mySyncFiles;
	BOOL myHasCreatedConfigFile;
	BOOL myTerminated;
	id myObserver;
	ABSTRACT_RECORDSET myDestRS;
	char myTableName[255];
	BOOL myInRestore;
	ABSTRACT_RECORDSET myAuditsRS;
	ABSTRACT_RECORDSET myChangeLogRS;
	ABSTRACT_RECORDSET myDepositsRS;
	ABSTRACT_RECORDSET myDepositsDetailsRS;
	ABSTRACT_RECORDSET myExtractionsRS;
	ABSTRACT_RECORDSET myExtractionsDetailsRS;
	ABSTRACT_RECORDSET myZCloseRS;

	COLLECTION mySyncFilesCollection;
	OMUTEX myMutex;
	BOOL myHasToSync;

	id mySplashBackup;
	BOOL myBackupCanceled;
	BackupType myCurrentBackupType;
	
	BackupType mySuggestedBackup;

	BOOL myIsAutomaticBackup;
	BOOL myFinishWithError;

	// variables utilizadas para el progressbar del backup
	int myCurrentBackupTablesCount;
	int myValueToIncBackupTables;

	// variables utilizadas para el progressbar del restore
	int myCurrentRestoreTablesCount;
	int myValueToIncRestoreTables;

	// atributos de la nueba tabla backups.dat
	int myLastAuditId;
	int myLastAuditDetailId;
	int myLastDropId;
	int myLastDropDetailId;
	int myLastDepositId;
	int myLastDepositDetailId;
	int myLastZcloseId;
	datetime_t myBackupTransDate;
	datetime_t myBackupSettDate;
	datetime_t myBackupUserDate;
	unsigned char myTableCheckList[15];

}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;


/**/
- (int) getCurrentRestoreTablesCount;

/**/
- (void) incCurrentRestoreTablesCount;

/**/
- (id) getSplashBackup;

/**/
- (void) setSplashBackup: (id) anObserver;

/**/
- (void) setFinishWithError: (BOOL) aValue;

/**/
- (BOOL) getFinishWithError;

/**/
- (void) setBackupCanceled: (BOOL) aValue;

/**/
- (BOOL) getBackupCanceled;

/**/
- (BOOL) getSuggestedBackup;

/**/
- (void) setCurrentBackupType: (BackupType) aValue;

/**/
- (BackupType) getCurrentBackupType;

/**/
- (void) syncRecord: (char *) aTableName buffer: (char *) aBuffer;

/**/
- (void) syncBackupFiles;

/**/
- (void) syncTransactionsBackupFiles;

/**/
- (void) syncSettingsBackupFiles;

/**/
- (void) initBackupFileSystem;

/**/
- (void) reinitTransactionsBackupFiles;

/**/
- (unsigned long) getLastRowValue: (char *) aTableName field: (char *) aFieldName;

/**/
- (void) setTerminated: (BOOL) aTerminated;

/**/
- (void) dumpTables;

/**/
- (void) dumpTablesToRestore: (RestoreType) aRestoreType;

/**/
- (BOOL) replaceRestoredTablesToDB: (RestoreType) aRestoreType;

/**/
- (void) dumpTablesToUpdate;

/**/
- (void) copyUpdatedConfigTablesToCopyFiles;

/**/
- (void) setObserver: (id) anObserver;

/** Esto configura los datos para restaurar, pero no efecuta el restore, luego debe llamarse al metodo restore() )*/
- (void) setRestoreFile: (char *) aTableName destRS: (ABSTRACT_RECORDSET) aDestRS;

/** Efectua el restore con los metodos configurado en setRestoreFile() */
- (void) restore;

/**/
- (void) beginRestore;

/**/
- (void) endRestore;

/**/
- (BOOL) inRestore;

/** Indica si el restore finalizo con error */
- (BOOL) isRestoreFailure;

/** Indica si el restore finalizo con error */
- (BOOL) isRestoreOk;

/**/
- (BOOL) shouldAuditRestoreError;

/** crea un archivo local con el nombre de la tabla de configuracion que se esta
 *  haciendo el restore. De esta manera si se corta la energia al iniciar se puede saber
 *  si dicha tabla quedo daniada o no y en base a esto se tomaran las medidas necesarias.
 */
- (void) beginCriticalRestoreSection: (char*) aTableName;

/** elimina el archivo critico de restore */
- (void) endCriticalRestoreSection: (char*) aTableName;

/** indica si existe el archivo critico de restore de la tabla */
- (BOOL) existCriticalRestoreFile: (char*) aTableName;

/** crequea que no haya quedado alguna tabla mal luego de un restore fallido */
- (void) checkRestoredTables: (id) anObserver;

/**/
- (void) setLastAuditId: (int) aValue;
- (int) getLastAuditId;

- (void) setLastAuditDetailId: (int) aValue;
- (int) getLastAuditDetailId;

- (void) setLastDropId: (int) aValue;
- (int) getLastDropId;

- (void) setLastDropDetailId: (int) aValue;
- (int) getLastDropDetailId;

- (void) setLastDepositId: (int) aValue;
- (int) getLastDepositId;

- (void) setLastDepositDetailId: (int) aValue;
- (int) getLastDepositDetailId;

- (void) setLastZcloseId: (int) aValue;
- (int) getLastZcloseId;

- (void) setBackupTransDate: (datetime_t) aValue;
- (datetime_t) getBackupTransDate;

- (void) setBackupSettDate: (datetime_t) aValue;
- (datetime_t) getBackupSettDate;

- (void) setBackupUserDate: (datetime_t) aValue;
- (datetime_t) getBackupUserDate;

- (void) setTableCheckList: (unsigned char*) aValue;
- (unsigned char*) getTableCheckList;

- (void) initBackupTable;

/**/
- (void) beginBackupTransactions;
- (void) beginBackupManualTrans;

/**/
- (void) endBackupTransactions;

/**/
- (BOOL) isBackupTransactionsFailure;
- (BOOL) isBackupManualTransFailure;

/**
 * Almacena los valores correspondientes al backup de transacciones
 */
- (void) saveTransBackupIds;

/**
 * Almacena la fecha/hora correspondientes al backup de transacciones
 */
- (void) saveTransBackupDate;

/**
 * Almacena la los valores correspondientes a la tabla de checks
 */
- (void) initTransBackupTableCheck;

/**
 * Almacena los valores correspondientes al backup de settings
 */
- (void) saveSettBackupValues;

/**
 * Almacena los valores correspondientes al backup de usuarios
 */
- (void) saveUserBackupValues;

/**
 * Marca la tabla para indicar que se inicio o finalizo el proceso de escritura en la misma
 */
- (void) checkTable: (id) aTable bitValue: (int) aBitValue;

/**
 * Indica si alguna tabla se encuentra incompleta por interrupcion de copiado o backup
 */
- (BOOL) isCheckTablesOk;

/**
 * Indica si la tabla pasada como parametro se encuentra incompleta por interrupcion 
 * de copiado o backup. Si esta ok devuelve la tabla
 */
- (id) isCheckTableOk: (char *) aTableName;

@end

#endif
