#include "CimBackup.h"
#include "system/db/all.h"
#include "SafeBoxRecordSet.h"
#include "SafeBoxHAL.h"
#include "CtSystem.h"
#include "CimManager.h"
#include "JSplashBackupForm.h"
#include "CimGeneralSettings.h"
#include "InputKeyboardManager.h"
#include "JUserLoginForm.h"
#include "Audit.h"
#include "Persistence.h"
#include "UICimUtils.h"

#define BACKUP_TIME							30000		// 30 segundos
#define BACKUP_FILE_NAME				"backup"
#define BACKUP_MANUAL_FILE_NAME "backup_manual"
#define RESTORE_FILE_NAME				"restore"
#define RESTORE_FILE_NAME_OK		"audit_restore_ok"
#define RESTORE_FILE_NAME_ERROR	"audit_restore_error"

//#define LOG(args...) doLog(0,args)

#define DISABLE_CIM_BACKUP		1

/** Sync File structure */
typedef struct {
	char tableName[255];
	char *buffer;
} SyncFile;

/** Sync file flag structure */
typedef struct {
	char tableName[255];
	BOOL syncFileFlag;
} SyncFileStruct;

@implementation CimBackup

static CIM_BACKUP singleInstance = NULL; 

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
	TABLE sourceTable;
	SyncFileStruct *syncfStruct;

#ifdef DISABLE_CIM_BACKUP
	return self;
#endif

	mySyncFiles = [SyncQueue new];
	myHasCreatedConfigFile = FALSE;
	myTerminated = FALSE;
	myObserver = NULL;
	myInRestore = FALSE;
	myBackupCanceled = FALSE;

	myMutex = [OMutex new];

    //************************* logcoment
	//doLog(0,"Init recordSet\n");

	mySyncFilesCollection = [Collection new];
	
	// audits
	sourceTable = [[DB getInstance] getTable: "audits"];
	myAuditsRS = [sourceTable getNewRecordSet];
	[myAuditsRS open];
	[myAuditsRS moveLast];

	syncfStruct = malloc(sizeof(SyncFileStruct));
	stringcpy(syncfStruct->tableName, "audits");
	syncfStruct->syncFileFlag = FALSE;
	[mySyncFilesCollection add: (void*) syncfStruct];

	// change_log
	sourceTable = [[DB getInstance] getTable: "change_log"];
	myChangeLogRS = [sourceTable getNewRecordSet];
	[myChangeLogRS open];
	[myChangeLogRS moveLast];

	syncfStruct = malloc(sizeof(SyncFileStruct));
	stringcpy(syncfStruct->tableName, "change_log");
	syncfStruct->syncFileFlag = FALSE;
	[mySyncFilesCollection add: (void*) syncfStruct];

	// deposits
	sourceTable = [[DB getInstance] getTable: "deposits"];
	myDepositsRS = [sourceTable getNewRecordSet];
	[myDepositsRS open];
	[myDepositsRS moveLast];

	syncfStruct = malloc(sizeof(SyncFileStruct));
	stringcpy(syncfStruct->tableName, "deposits");
	syncfStruct->syncFileFlag = FALSE;
	[mySyncFilesCollection add: (void*) syncfStruct];

	// deposit_details
	sourceTable = [[DB getInstance] getTable: "deposit_details"];
	myDepositsDetailsRS = [sourceTable getNewRecordSet];
	[myDepositsDetailsRS open];
	[myDepositsDetailsRS moveLast];

	syncfStruct = malloc(sizeof(SyncFileStruct));
	stringcpy(syncfStruct->tableName, "deposit_details");
	syncfStruct->syncFileFlag = FALSE;
	[mySyncFilesCollection add: (void*) syncfStruct];

	// extractions
	sourceTable = [[DB getInstance] getTable: "extractions"];
	myExtractionsRS = [sourceTable getNewRecordSet];
	[myExtractionsRS open];
	[myExtractionsRS moveLast];

	syncfStruct = malloc(sizeof(SyncFileStruct));
	stringcpy(syncfStruct->tableName, "extractions");
	syncfStruct->syncFileFlag = FALSE;
	[mySyncFilesCollection add: (void*) syncfStruct];

	// extraction_details
	sourceTable = [[DB getInstance] getTable: "extraction_details"];
	myExtractionsDetailsRS = [sourceTable getNewRecordSet];
	[myExtractionsDetailsRS open];
	[myExtractionsDetailsRS moveLast];

	syncfStruct = malloc(sizeof(SyncFileStruct));
	stringcpy(syncfStruct->tableName, "extraction_details");
	syncfStruct->syncFileFlag = FALSE;
	[mySyncFilesCollection add: (void*) syncfStruct];

	// zclose
	sourceTable = [[DB getInstance] getTable: "zclose"];
	myZCloseRS = [sourceTable getNewRecordSet];
	[myZCloseRS open];
	[myZCloseRS moveLast];

	syncfStruct = malloc(sizeof(SyncFileStruct));
	stringcpy(syncfStruct->tableName, "zclose");
	syncfStruct->syncFileFlag = FALSE;
	[mySyncFilesCollection add: (void*) syncfStruct];

	myHasToSync = FALSE;
	mySplashBackup = NULL;
	myCurrentBackupType = BackupType_UNDEFINED;
	myCurrentBackupTablesCount = 0;
	myValueToIncBackupTables = 0;
	myCurrentRestoreTablesCount = 0;
	myValueToIncRestoreTables = 0;
	mySuggestedBackup = BackupType_UNDEFINED;
	myIsAutomaticBackup = FALSE;
	myFinishWithError = FALSE;

	// inicializo los atributos de la tabla backup
	[self initBackupTable];

	return self;
}

/**/
- (int) getCurrentRestoreTablesCount
{
	return myCurrentRestoreTablesCount;
}

/**/
- (void) incCurrentRestoreTablesCount
{
	myCurrentRestoreTablesCount += myValueToIncRestoreTables;
	if (myCurrentRestoreTablesCount >= 100) myCurrentRestoreTablesCount = 99;
}

- (id) getSplashBackup
{
	return mySplashBackup;
}

- (void) setSplashBackup: (id) anObserver
{
	mySplashBackup = anObserver;
}

/**/
- (void) setFinishWithError: (BOOL) aValue
{
	myFinishWithError = aValue;
}

/**/
- (BOOL) getFinishWithError
{
	return myFinishWithError;
}

/**/
- (void) setBackupCanceled: (BOOL) aValue
{
	myBackupCanceled = aValue;

	if (myBackupCanceled) {
		// audito la cancelacion del backup
		[Audit auditEventCurrentUser: Event_BACKUP_CANCELED additional: "" station: 0 logRemoteSystem: FALSE];
    //************************* logcoment
//		doLog(0,"BackUp Cancelado\n");
	}
}

/**/
- (BOOL) getBackupCanceled
{
	return myBackupCanceled;
}

/**/
- (BOOL) getSuggestedBackup
{
	return mySuggestedBackup;
}

/**/
- (void) setCurrentBackupType: (BackupType) aValue
{
	myCurrentBackupType = aValue;

	// calculo la cantidad de tablas a procesar para poder armar los valores a mostrar en
	// el progressbar
	myCurrentBackupTablesCount = 0;
	myValueToIncBackupTables = 0;

	if (myCurrentBackupType == BackupType_ALL) {
		// Total de tablas 31;
		myValueToIncBackupTables = 3; // (100/31): de 3 en 3
	}

	if (myCurrentBackupType == BackupType_TRANSACTIONS) {
		// Total de tablas 7;
		myValueToIncBackupTables = 14; // (100/7): de 14 en 14
	}

	if (myCurrentBackupType == BackupType_SETTINGS) {
		// Total de tablas 20;
		myValueToIncBackupTables = 5; // (100/20): de 5 en 5
	}

	if (myCurrentBackupType == BackupType_USERS) {
		// Total de tablas 4;
		myValueToIncBackupTables = 25; // (100/4): de 25 en 25
	}

}

/**/
- (void) setRestoreTableCount: (RestoreType) aRestoreType
{

	// calculo la cantidad de tablas a procesar para poder armar los valores a mostrar en
	// el progressbar
	myCurrentRestoreTablesCount = 0;
	myValueToIncRestoreTables = 0;

	if (aRestoreType == RestoreType_ALL) {
		// Total de tablas 31 + 1 de dump
		myValueToIncRestoreTables = 3; // (100/32): de 3 en 3
	}

	if (aRestoreType == RestoreType_TRANSACTIONS) {
		// Total de tablas 7
		myValueToIncRestoreTables = 14; // (100/7): de 14 en 14
	}

	if (aRestoreType == RestoreType_SETTINGS) {
		// Total de tablas 20 + 1 de dump
		myValueToIncRestoreTables = 4; // (100/21): de 4 en 4
	}

	if (aRestoreType == RestoreType_USERS) {
		// Total de tablas 4 + 1 de dump
		myValueToIncRestoreTables = 20; // (100/5): de 20 en 20
	}

}

/**/
- (BackupType) getCurrentBackupType
{
	return myCurrentBackupType;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) debugSyncFileCollection
{
	int i;
	SyncFileStruct* syncfStruct;

	for (i=0; i<[mySyncFilesCollection size]; ++i) {
		syncfStruct = (SyncFileStruct*) [mySyncFilesCollection at: i];

		//doLog ("Table name %s   -   Sync %d  \n", syncfStruct->tableName, syncfStruct->syncFileFlag);

	}

}

/**/
- (SyncFileStruct*) getFileStructByName: (char*) aTableName
{
	int i;
	SyncFileStruct* syncfStruct;

	for (i=0; i<[mySyncFilesCollection size]; ++i) {
		syncfStruct = (SyncFileStruct*) [mySyncFilesCollection at: i];

		if (strcmp(syncfStruct->tableName, aTableName) == 0) return syncfStruct; 

	}

	return NULL;
}

/**/
- (void) setSyncFileFlag: (SyncFileStruct*) aSyncfStruct value: (BOOL) aValue
{
	[myMutex lock];
	aSyncfStruct->syncFileFlag = aValue;
	[myMutex unLock];
}

/**/
- (BOOL) existFilesToSync
{
	SyncFileStruct* syncfStruct;
	int i;	
	BOOL existFiles = FALSE;

	for (i=0; i<[mySyncFilesCollection size]; ++i) {

		syncfStruct = (SyncFileStruct*) [mySyncFilesCollection at: i];

		if (syncfStruct->syncFileFlag == TRUE) existFiles = TRUE; 

	}

	return existFiles;

}

/**/
- (void) setHasToSync: (BOOL) aValue
{
	[myMutex lock];
	myHasToSync = aValue;
	[myMutex unLock];
}

/**/
- (BOOL) hasToSync
{
	return myHasToSync;
}

/**/
- (void) syncRecord: (char *) aTableName buffer: (char *) aBuffer
{
	SyncFileStruct *syncfStruct;

#ifdef DISABLE_CIM_BACKUP
	return;
#endif
/*
	syncf = malloc(sizeof(SyncFile));

	stringcpy(syncf->tableName, aTableName);
	recordSize = [[[DB getInstance] getTable: aTableName] getRecordSize];
	syncf->buffer = malloc(recordSize);
	memcpy(syncf->buffer, aBuffer, recordSize);

	[mySyncFiles pushElement: syncf];
*/
/*************************************************/

	//doLog(0,"CimBackup -> syncRecord table = %s\n", aTableName);

 	syncfStruct = [self getFileStructByName: aTableName];
	assert(syncfStruct);

	//doLog(0,"table struct returned = %s\n", syncfStruct->tableName);

	// setea para que tiene que sincronizar
	[self setSyncFileFlag: syncfStruct value: TRUE];

	[self setHasToSync: TRUE];

	//[self debugSyncFileCollection];
	
}

/**/
- (void) copyBackupFile: (TABLE) aTable 
		path: (char*) aSourcePath 
		clearFile: (BOOL) aClearFile
		deleteAfterCopy: (BOOL) aDeleteAfterCopy
		fromFile: (char*) aFromFile
{
  char fileName[255];
  ABSTRACT_RECORDSET recordSet;
	FILE *f;

	if (strlen(aFromFile) == 0)
  	sprintf(fileName, "%s%s.dat", aSourcePath, [aTable getName]);
	else
		sprintf(fileName, "%s%s.dat", aSourcePath, aFromFile);

	// verifico que el archivo origen desde donde se va a copiar exista
	f = fopen(fileName, "rb");
	if (!f) return;
	fclose(f);

    //*********************logcoment
//  doLog(0,"CimBackup -> copy table %s from file %s...\n", [aTable getName], fileName);

  recordSet = [aTable getNewRecordSet];

	// *********** marco la tabla antes de la edicion ***********
	[self checkTable: aTable bitValue: 1];

	// Limpio primero el archivo si corresponde
	if (aClearFile) 
		[recordSet clearFile];
  
	[recordSet copyFileFrom: fileName observer: mySplashBackup];
  [recordSet free];

	// *********** marco la tabla despues de la edicion ***********
	if (!myBackupCanceled)
		[self checkTable: aTable bitValue: 0];

	if (aDeleteAfterCopy) {
    //************************* logcoment
//		doLog(0,"Deleting file %s\n", fileName);
		unlink(fileName);
	}
  
    //*********************logcoment
//  doLog(0,"CimBackup -> finish copy backup file\n");

}

/**/
- (void) initFile: (TABLE) aTable 
		createFile: (BOOL) aCreateFile 
		path: (char*) aSourcePath 
		clearFile: (BOOL) aClearFile
		deleteAfterCopy: (BOOL) aDeleteAfterCopy
		
{
  char fileName[255];
  ABSTRACT_RECORDSET recordSet;
	FILE *f;
	char msg[50];

	sprintf(fileName, "%s%s.dat", aSourcePath, [aTable getName]);

	// Si no tiene que crear el archivo, solo copiarlo entonces verifico que el
	// archivo origen desde donde se va a copiar exista
	if (!aCreateFile) {
		f = fopen(fileName, "rb");
		if (!f) return;
		fclose(f);
	}

    //*********************logcoment
//  doLog(0,"CimBackup -> creating table %s from file %s...\n", [aTable getName], fileName);

  recordSet = [aTable getNewRecordSet];

	// *********** marco la tabla antes de la edicion ***********
	[self checkTable: aTable bitValue: 1];

	// Limpio primero el archivo si corresponde
	if (aClearFile) 
		[recordSet clearFile];

  // esto es para mostrar un detalle de que esta procesando
  if ([[CtSystem getInstance] getSplash] != NULL) {
      if (aCreateFile) 
        sprintf(msg, "Creating %s ...",[aTable getName]);
      else
        sprintf(msg, "Copying %s ...",[aTable getName]);
      [[[CtSystem getInstance] getSplash] updateDisplay: 23 msg: msg];
  }
  
	if (aCreateFile)
  	[recordSet createFileFrom: fileName];
	else 
		[recordSet copyFileFrom: fileName];

  [recordSet free];

	// *********** marco la tabla despues de la edicion ***********
	[self checkTable: aTable bitValue: 0];

	if (aDeleteAfterCopy) {
        //************************* logcoment
		//doLog(0,"Deleting file %s\n", fileName);
		unlink(fileName);
	}
  
//  doLog(0,"CimBackup -> finish creating file\n");
    //*********************logcoment

}

/**/
- (void) initBackupFileSystem
{
  COLLECTION tables;
  int i;
  TABLE table;

/*
#ifdef DISABLE_CIM_BACKUP
	return;
#endif
*/
  tables = [[DB getInstance] getTables];

    //*********************logcoment
//  doLog(0,"CimBackup -> initBackupFileSystem\n");

	// Si no existe el archivo de configuracion lo crea
	if (![SafeBoxHAL fsExists: 0]) {
		[SafeBoxHAL fsCreateFile: 0 unitSize: 1 fileType: SafeBoxFileType_RANDOM rows: 450000];
		myHasCreatedConfigFile = TRUE;
	}

	// VERIFICO SI DEBO COPIAR LAS TABLAS DESDE DIRECTORIO INIT_FILES_PATH
  for (i = 0; i < [tables size]; ++i) {
   
    table = [tables at: i];

    //doLog(0,"getFileId [%d] table [%s]\n", [table getFileId],[table getName]);

    if ([table getFileId] > 0) {
				// tablas de transactions (audits, deposits, extractions, zcloses)
        if (![SafeBoxHAL fsExists: [table getFileId]]) {
    //*********************logcoment
//          doLog(0,"CimBackup -> table %s doesnt exists, creating it...\n", [table getName]);
          [self initFile: table createFile: TRUE path: INIT_FILES_PATH clearFile: FALSE deleteAfterCopy: FALSE];
        }

    } else if ([table getFileId] == 0 && myHasCreatedConfigFile) {
				// tablas de backup
    //*********************logcoment
				//doLog(0,"CimBackup -> table %s doesnt exists, copy it...\n", [table getName]);
				[self initFile: table createFile: FALSE path: INIT_FILES_PATH clearFile: FALSE deleteAfterCopy: FALSE];
		}
  
  }

	// Recorro las tablas una vez mas por si alguien dejo algun archivo para copiar
	// dentro del CT8016
	// VERIFICO SI DEBO COPIAR LAS TABLAS DESDE DIRECTORIO COPY_FILES_PATH
  for (i = 0; i < [tables size]; ++i) {
   
    table = [tables at: i];
    
    if ([table getFileId] != -1) {

		 	[self initFile: table createFile: FALSE path: COPY_FILES_PATH clearFile: TRUE deleteAfterCopy: TRUE];
		}
  
  }

	// Recorro las tablas una vez mas por si alguien dejo algun archivo para copiar
	// del backup del dump de configuracion
	// VERIFICO SI DEBO COPIAR LAS TABLAS DESDE DIRECTORIO DUMP_BCK_FILES_PATH
  for (i = 0; i < [tables size]; ++i) {
   
    table = [tables at: i];
    
    if ([table getFileId] != -1) {
		 	[self initFile: table createFile: FALSE path: DUMP_BCK_FILES_PATH clearFile: FALSE deleteAfterCopy: TRUE];
		}
  
  }

}

/**/
- (void) doSyncRecord: (char *) aTableName buffer: (char *) aBuffer
{
	TABLE backupTable;
	int fileId;
	char backupFile[255];

	sprintf(backupFile, "%s_bck", aTableName);
	//doLog(0,"CimBackup -> sinc. reg. de %s\n", backupFile);

	backupTable = [[DB getInstance] getTable: backupFile];
	fileId = [backupTable getFileId];
	[SafeBoxHAL fsWrite: fileId numRows: 1 unitSize: [backupTable getRecordSize] buffer: aBuffer];
}

/**/
- (void) syncFile: (char *) aSourceFile sourceRS: (ABSTRACT_RECORDSET) aSourceRS
{
	TABLE sourceTable;
	TABLE backupTable;
	int count = 0,  i;
	char lastBackupBuf[255];
	char aux[255];
	int fileId;
	SafeBoxFileStatus status;
	char backupFile[255];
	char msg[50];

	// El mecanismo para sincronizar archivos es el siguiente:
	//	(1) Pararse en el ultimo registro de la tabla de backup "A"
	//	(2) Pararse en el ultimo registro de la tabla de ct8016 "B"
	//	(3) Recorrer del ultimo registro de "B" hacia atras hasta que "A" = "B"
	//	(4) Recorrer "B" a partir de ahi hacia adelante escribiendo cada registro en "A"

	sprintf(backupFile, "%s_bck", aSourceFile);

  // esto es para mostrar un detalle de que esta procesando desde la pantalla CtSystem
  if ([[CtSystem getInstance] getSplash] != NULL) {
			formatResourceStringDef(msg, RESID_CYNCHRONIZE_TABLE, "Sync %s ...", aSourceFile);
      [[[CtSystem getInstance] getSplash] updateDisplay: 27 msg: msg];
  }

	sourceTable = [[DB getInstance] getTable: aSourceFile];
	backupTable = [[DB getInstance] getTable: backupFile];
	fileId = [backupTable getFileId];

	// Leo el ultimo registro del archivo backup
	[SafeBoxHAL fsStatus: fileId status: &status];

	if (status.currentRows != 0) {
		[SafeBoxHAL fsSeek: fileId offset: -1 whence: SEEK_END];
		[SafeBoxHAL fsRead: fileId numRows: 1 unitSize: [sourceTable getRecordSize] buffer: aux];
		memcpy(lastBackupBuf, aux, [sourceTable getRecordSize]);
	}

	// comparo registros de ambas tablas para ubicarme en la posicion de comienzo
	[aSourceRS moveLast];
	while (![aSourceRS bof]) {

		if (status.currentRows != 0) {
			if (memcmp([aSourceRS getRecordBuffer], lastBackupBuf, [sourceTable getRecordSize]) == 0) break;
		}

		count++;

		[aSourceRS movePrev];
	}

    //*********************logcoment
/*	if (count > 0)
		doLog(0,"CimBackup -> Debe sincronizar %d filas de %s\n", count, backupFile);
*/
	for (i = 0; i < count; ++i) {

		// si se cancelo el backup entonces aborto del proceso
		if (myBackupCanceled) break;

    // esto es para mostrar un detalle de que esta procesando desde pantalla CtSystem
    if ([[CtSystem getInstance] getSplash] != NULL) {
        formatResourceStringDef(msg, RESID_CYNCHRONIZE_RECORD, "Record %d/%d", i+1, count);
        [[[CtSystem getInstance] getSplash] setLabel2: msg];
    }

    // esto es para mostrar un detalle de que esta procesando desde pantalla CimBackup
    if (mySplashBackup) {
				formatResourceStringDef(msg, RESID_CYNCHRONIZE_RECORD, "Record %d/%d", i+1, count);
        [mySplashBackup setLabel2: msg];
    }

    //*********************logcoment
//		doLog(0,"Sinc reg %d/%d\n", i+1, count);
		[aSourceRS moveNext];

		[SafeBoxHAL fsWrite: fileId numRows: 1 unitSize: [backupTable getRecordSize] buffer: [aSourceRS getRecordBuffer]];

	}

}

/**/
- (unsigned long) getValue: (Field *) aField buffer: (char *) aBuffer
{
	unsigned long value;
	unsigned short svalue;
	unsigned long lvalue;
	unsigned char cvalue;

	if (aField->len == 2) {
		memcpy(&svalue, aBuffer + aField->offset, aField->len);
		svalue = B_ENDIAN_TO_SHORT(svalue);
		value = svalue;
	} else if (aField->len == 4) {
		memcpy(&lvalue, aBuffer + aField->offset, aField->len);
		lvalue = B_ENDIAN_TO_LONG(lvalue);
		value = lvalue;
	} else {
		memcpy(&cvalue, aBuffer + aField->offset, aField->len);
		value = cvalue;
	}

	return value;

}

/**/
- (void) dumpTable: (char *) aTableName
{
	char destFileName[255];
	FILE *f;
	ABSTRACT_RECORDSET rs;
	char *buf;
	int recordSize;

	sprintf(destFileName, "%s/%s.dat", DUMP_FILES_PATH, aTableName);

    //*********************logcoment
//	doLog(0, "CimBackup -> dump de la tabla %s en %s\n", aTableName, destFileName);

	f = fopen(destFileName, "w+b");
	if (!f) {
    //*********************logcoment
		//doLog(0,"Error -> no se puede crear el archivo %s\n", destFileName);
		return;
	}

	rs = 	[[DBConnection getInstance] createRecordSet: aTableName];
	[rs open];
	[rs moveBeforeFirst];
	recordSize = [rs getRecordSize];
	
	while ([rs moveNext]) {

		buf = [rs getRecordBuffer];
		fwrite(buf, 1, recordSize, f);

	}

	[rs close];
	[rs free];

	fclose(f);
}

/**/
- (void) dumpTables
{
	COLLECTION tables;
	TABLE table;
	int i;
	char command[255];

	makeDir_OSDep(DUMP_FILES_PATH);

	tables = [[DB getInstance] getTables];

	for (i = 0; i < [tables size]; ++i)	{

		table = [tables at: i];

		// Dump de las tablas de configuracion dentro de la placa
    if ([table getFileId] == 0) {
		
			[self dumpTable: [table getName]];
		}

		// Dump de las tablas de configuracion dentro del CT8016
    /*if ([table getFileId] == -1 && [table getTableType] == ROP_TABLE_SINGLE) {
			sprintf(command, "cp %s %s/", [table getFileName], DUMP_FILES_PATH);		
			doLog(0,"cmd = %s\n", command);
			system(command);
		}*/

	}

	sprintf(command, "tar -cf " BASE_VAR_PATH "/data.tar %s/*dat", DUMP_FILES_PATH);
	system(command);

}

/**/
- (void) checkRestoredTables: (id) anObserver
{
	COLLECTION tables;
	TABLE table;
	int i;
	char command[255];
	char tableName[50];
	char fileNameToDelete[255];
	STRING_TOKENIZER tokenizer = [StringTokenizer new];

	// recorro las tablas de configuracion (settings y usuarios) y verifico que no haya
	// quedado una marca de que la misma no finalizo el preoceso de restore

	tables = [[DB getInstance] getTables];

	[tokenizer setDelimiter: "_bck"];
	[tokenizer setTrimMode: TRIM_ALL];

	for (i = 0; i < [tables size]; ++i)	{

		table = [tables at: i];

		// obtengo el nombre de la tabla y le quito el "_bck" del final
		[tokenizer restart];
		[tokenizer setText: [table getName]];
		if ([tokenizer hasMoreTokens]) 
			[tokenizer getNextToken: tableName];

		// Dump de las tablas de configuracion dentro de la placa
    if ([table getFileId] == 0) {

			// me fijo si existe el archivo critico de la tabla
			// en caso de que exista intento hacer nuevamente es restore de dicha tabla
			if ([self existCriticalRestoreFile: tableName]) {

                //************************* logcoment
				//doLog(0,"Recuperando tabla critica: [%s]\n", tableName);

				if (anObserver) {
					[anObserver updateDisplay: 26 msg: "Recovering table"];
					[anObserver setLabel2: "Wait please..."];
				}

				makeDir_OSDep(DUMP_FILES_PATH);

				// 1) hago el dump de la tabla
				[self dumpTable: [table getName]];

				if (anObserver) {
					[anObserver updateDisplay: 28 msg: "Recovering table."];
					[anObserver setLabel2: "Wait please..."];
				}

				// 2) muevo la tabla de /var/data a /rw/CT8016/data
				sprintf(command, "mv " DUMP_FILES_PATH "/%s.dat %s", [table getName], BASE_PATH "/CT8016/data/");
				system(command);

				if (anObserver) {
					[anObserver updateDisplay: 29 msg: "Recovering table.."];
					[anObserver setLabel2: "Wait please..."];
				}

				// 3) elimino la tabla original de /rw/CT8016/data
				sprintf(fileNameToDelete, BASE_PATH "/CT8016/data/%s.dat", tableName);
				unlink(fileNameToDelete);

				if (anObserver) {
					[anObserver updateDisplay: 30 msg: "Recovering table..."];
					[anObserver setLabel2: "Wait please..."];
				}

				// 4) renombro la tabla restaurada quitandole el _bck del final
				sprintf(command, "mv " BASE_PATH "/CT8016/data/%s.dat " BASE_PATH "/CT8016/data/%s.dat", [table getName], tableName);
				system(command);

				if (anObserver) {
					[anObserver updateDisplay: 31 msg: "Recovering table."];
					[anObserver setLabel2: "Wait please..."];
				}

				// 5) elimina archivo de chequeo para indicar que finalizo seccion critica
				[self endCriticalRestoreSection: tableName];

      //************************* logcoment
//				doLog(0,"Tabla critica recuperada: [%s]\n", tableName);
//				doLog(0,"** EL SISTEMA SERA REINICIADO **\n", tableName);
//				doLog(0,"** EL SISTEMA SERA REINICIADO **\n");

				if (anObserver) {
					[anObserver updateDisplay: 32 msg: "Recovering table.."];
					[anObserver setLabel2: "restarting..."];
				}

				//reinicio la aplicacion para que tome la nueva tabla
				exit(23);

			}
		} // if
	} // for

	[tokenizer free];

}

/**/
- (BOOL) replaceRestoredTablesToDB: (RestoreType) aRestoreType
{
	COLLECTION tables;
	TABLE table;
	int i;
	char command[255];
	int result;
	BOOL replaceTable = TRUE;
	char tableName[50];
	char fileNameToDelete[255];
	char msg[50];
	STRING_TOKENIZER tokenizer = [StringTokenizer new];

	tables = [[DB getInstance] getTables];

	[tokenizer setDelimiter: "_bck"];
	[tokenizer setTrimMode: TRIM_ALL];

	if (myObserver) {
		[myObserver setCaption: getResourceStringDef(RESID_COPYING_TABLE_MSG, "copiando tabla...")];
		[myObserver setCaption2: ""];
	}

	for (i = 0; i < [tables size]; ++i)	{

		table = [tables at: i];

		// obtengo el nombre de la tabla y le quito el "_bck" del final
		[tokenizer restart];
		[tokenizer setText: [table getName]];
		if ([tokenizer hasMoreTokens]) 
			[tokenizer getNextToken: tableName];

		// Dump de las tablas de configuracion dentro de la placa
    if ([table getFileId] == 0) {

			if (aRestoreType != RestoreType_ALL) {
				if (aRestoreType == RestoreType_SETTINGS) {
					replaceTable = TRUE;
					// solo hago dump de tablas de settings
					if ( (strcmp(tableName,"doors_by_user") == 0) ||
							(strcmp(tableName,"users") == 0) ||
							(strcmp(tableName,"profiles") == 0) ||
							(strcmp(tableName,"dual_access") == 0) ) replaceTable = FALSE;
				} else if (aRestoreType == RestoreType_USERS) {
					replaceTable = FALSE;
					// solo hago dump de tablas de usuarios
					if ( (strcmp(tableName,"doors_by_user") == 0) ||
							(strcmp(tableName,"users") == 0) ||
							(strcmp(tableName,"profiles") == 0) ||
							(strcmp(tableName,"dual_access") == 0) ) replaceTable = TRUE;
				}
			} else replaceTable = TRUE; // hago el dump de todas las tablas

			// hago el replace de la tabla
			if (replaceTable) {

				if (myObserver) {
					[self incCurrentRestoreTablesCount];
					[myObserver advanceTo: [self getCurrentRestoreTablesCount]];
					sprintf(msg, "%s...", tableName);
					[myObserver setCaption2: msg];
				}

				// 1) muevo la tabla de /var/data a /rw/CT8016/data
				sprintf(command, "mv " DUMP_FILES_PATH "/%s.dat %s", [table getName], BASE_PATH "/CT8016/data/");
				result = system(command);
				if (result != 0) return FALSE;

				// 2) creo archivo de chequeo para indicar que comienza seccion critica
				[self beginCriticalRestoreSection: tableName];

				// 3) elimino la tabla original de /rw/CT8016/data
				sprintf(fileNameToDelete, BASE_PATH "/CT8016/data/%s.dat", tableName);
				unlink(fileNameToDelete);

				// 4) renombro la tabla restaurada quitandole el _bck del final
				sprintf(command, "mv " BASE_PATH "/CT8016/data/%s.dat " BASE_PATH "/CT8016/data/%s.dat", [table getName], tableName);
				result = system(command);
				if (result != 0) return FALSE;

				// 5) elimina archivo de chequeo para indicar que finalizo seccion critica
				[self endCriticalRestoreSection: tableName];

			}

		} // if
	} // for

	[tokenizer free];
	return TRUE;

}

/**/
- (void) dumpTablesToRestore: (RestoreType) aRestoreType
{
	COLLECTION tables;
	TABLE table;
	int i;
	BOOL dumpTable = TRUE;
	char tableName[50];
	char msg[50];
	STRING_TOKENIZER tokenizer = [StringTokenizer new];

	makeDir_OSDep(DUMP_FILES_PATH);

	tables = [[DB getInstance] getTables];

	[tokenizer setDelimiter: "_bck"];
	[tokenizer setTrimMode: TRIM_ALL];

	if (myObserver) {

		[self incCurrentRestoreTablesCount];
		[myObserver advanceTo: [self getCurrentRestoreTablesCount]];

		if (aRestoreType == RestoreType_ALL)
			[myObserver setCaption: getResourceStringDef(RESID_DUMP_ALL_MSG, "export todo...")];

		if (aRestoreType == RestoreType_SETTINGS)
			[myObserver setCaption: getResourceStringDef(RESID_DUMP_SETT_MSG, "export config...")];

		if (aRestoreType == RestoreType_USERS)
			[myObserver setCaption: getResourceStringDef(RESID_DUMP_USERS_MSG, "export usuarios...")];

		[myObserver setCaption2: ""];
	}

	for (i = 0; i < [tables size]; ++i)	{

		table = [tables at: i];

		// obtengo el nombre de la tabla y le quito el "_bck" del final
		[tokenizer restart];
		[tokenizer setText: [table getName]];
		if ([tokenizer hasMoreTokens]) 
			[tokenizer getNextToken: tableName];

		// Dump de las tablas de configuracion dentro de la placa
    if ([table getFileId] == 0) {

			if (aRestoreType != RestoreType_ALL) {
				if (aRestoreType == RestoreType_SETTINGS) {
					dumpTable = TRUE;
					// solo hago dump de tablas de settings
					if ( (strcmp(tableName,"doors_by_user") == 0) ||
							(strcmp(tableName,"users") == 0) ||
							(strcmp(tableName,"profiles") == 0) ||
							(strcmp(tableName,"dual_access") == 0) ) dumpTable = FALSE;
				} else if (aRestoreType == RestoreType_USERS) {
					dumpTable = FALSE;
					// solo hago dump de tablas de usuarios
					if ( (strcmp(tableName,"doors_by_user") == 0) ||
							(strcmp(tableName,"users") == 0) ||
							(strcmp(tableName,"profiles") == 0) ||
							(strcmp(tableName,"dual_access") == 0) ) dumpTable = TRUE;
				}
			} else dumpTable = TRUE; // hago el dump de todas las tablas

			// hago el dump de la tabla
			if (dumpTable) {
				if (myObserver) {
					sprintf(msg, "%s...", [table getName]);
					[myObserver setCaption2: msg];
				}
				[self dumpTable: [table getName]];
			}

		} // if
	} // for

	[tokenizer free];

}

/**/
- (void) dumpTablesToUpdate
{
	COLLECTION tables;
	TABLE table;
	int i;
	char tableName[50];
	char command[512];
	STRING_TOKENIZER tokenizer = [StringTokenizer new];

	makeDir_OSDep(DUMP_FILES_PATH);

	[tokenizer setDelimiter: "_bck"];
	[tokenizer setTrimMode: TRIM_ALL];

	tables = [[DB getInstance] getTables];

	for (i = 0; i < [tables size]; ++i)	{

		table = [tables at: i];

		// obtengo el nombre de la tabla y le quito el "_bck" del final
		// si la version a actualizar es anterior a la RI20-RC01 las tablas traidas no
		// tendran el _bck al final.
		[tokenizer restart];
		[tokenizer setText: [table getName]];
		if ([tokenizer hasMoreTokens]) 
			[tokenizer getNextToken: tableName];

		// Dump de las tablas de configuracion
    if ([table getFileId] == 0) {
			// Solo hago el dump si la tabla aun no fue copiada a rw/CT8016/data
			if (![self existTableInData: tableName]) {
				// hago del dump de latabla
				[self dumpTable: [table getName]];

				// renombro la tabla dumpeada. Le quito el _bck del final ya que luego debe ser
				// copiada a /rw/CT8016/data
				// si la version a actualizar es anterior a la RI20-RC01 las tablas traidas no
				// tendran el _bck al final con lo cual no debo hacer el mv.
				if (strcmp([table getName], tableName) != 0) {
					sprintf(command, "mv " BASE_VAR_PATH "/data/%s.dat " BASE_VAR_PATH "/data/%s.dat", [table getName], tableName);
					system(command);
				}
			}
		}
	}

	[tokenizer free];
}

/*
 * Mueve las tablas modificadas a copyFiles
 */
- (void) copyUpdatedConfigTablesToCopyFiles
{
	COLLECTION tables;
	TABLE table;
	int i;
	char tableName[50];
	char tableNameBck[50];
	char command[512];
	STRING_TOKENIZER tokenizer = [StringTokenizer new];

	makeDir_OSDep(DUMP_FILES_PATH);

	[tokenizer setDelimiter: "_bck"];
	[tokenizer setTrimMode: TRIM_ALL];

	tables = [[DB getInstance] getTables];

	for (i = 0; i < [tables size]; ++i)	{

		table = [tables at: i];

		// obtengo el nombre de la tabla y le quito el "_bck" del final
		// si la version a actualizar es anterior a la RI20-RC01 las tablas traidas no
		// tendran el _bck al final.
		[tokenizer restart];
		[tokenizer setText: [table getName]];
		if ([tokenizer hasMoreTokens]) 
			[tokenizer getNextToken: tableName];

		// Recorro las tablas de configuracion y veo cual debo copiar a copyFiles
    if ([table getFileId] == 0) {
			if ([self mustUpdateTable: tableName]) {

				// si la version a actualizar es anterior a la RI20-RC01 las tablas traidas no
				// tendran el _bck al final con lo cual debo concatenar el _bck antes de copiar.
				strcpy(tableNameBck, [table getName]);
				if (strcmp(tableNameBck, tableName) == 0)
					strcat(tableNameBck,"_bck");

				sprintf(command, "cp " BASE_PATH "/CT8016/data/%s.dat " COPY_FILES_PATH "/%s.dat", tableName, tableNameBck);
				system(command);
			}
		}
	}

	[tokenizer free];
}

/*
 * Me indica si la tabla de configuracion ya fue copiada a rw/CT8016/data
 */
- (BOOL) existTableInData: (char*) aTableName
{
	FILE *f;
	char fileName[200];
	
	sprintf(fileName, BASE_PATH "/CT8016/data/%s.dat", aTableName);

	f = fopen(fileName, "r");
	
	if (!f) return FALSE;

	fclose(f);
	
	return TRUE;
}

/*
 * Me indica si la tabla fue modificada y debo guardarla nuevamente en la placa.
 */
- (BOOL) mustUpdateTable: (char*) aTableName
{
	FILE *f;
	char fileName[200];
	
	sprintf(fileName, BASE_PATH "/update/updatedb/updated/%s.ftd", aTableName);

	f = fopen(fileName, "r");
	
	if (!f) return FALSE;

	fclose(f);
	
	return TRUE;
}

/**/
- (void) setObserver: (id) anObserver
{
	myObserver = anObserver;
}

/**/
- (void) setRestoreFile: (char *) aTableName destRS: (ABSTRACT_RECORDSET) aDestRS
{
	stringcpy(myTableName, aTableName);
	myDestRS = aDestRS;
	[self incCurrentRestoreTablesCount];
}

/**/
- (void) restore
{
	[self restoreFile: myTableName destRS: myDestRS];
}

/**/
- (void) restoreFile: (char *) aTableName destRS: (ABSTRACT_RECORDSET) aDestRS
{
	// Copia un archivo desde la CIM de backup a la memoria flash del CT8016
	// Pisa todo el contenido del archivo si es que existe

	TABLE sourceTable;
	SafeBoxFileStatus status;
	char aux[255], sourceFile[255];
	int fileId;
	int i;
	Field *field;
	BOOL initialized = FALSE;
	unsigned long autoIncValue;
	char msg[50];

	sprintf(sourceFile, "%s_bck", aTableName);
    //************************* logcoment
	//doLog(0,"CimBackup -> restaurando archivo %s con %s\n", aTableName, sourceFile);

	sourceTable = [[DB getInstance] getTable: sourceFile];
	fileId = [sourceTable getFileId];

	// Leo el ultimo registro del archivo backup
	[SafeBoxHAL fsStatus: fileId status: &status];

    //************************* logcoment
	//doLog(0,"CimBackup -> debo restaurar %ld filas\n", status.currentRows);

	if (myObserver) {
		[myObserver advanceTo: [self getCurrentRestoreTablesCount]];
	}

	// No hay registros de backup, chau
	if (status.currentRows == 0) return;

	[SafeBoxHAL fsSeek: fileId offset: 0 whence: SEEK_SET];

	for (i = 0; i < status.currentRows; ++i) {

		// esto es para mostrar un detalle de que esta procesando desde pantalla CtSystem
		if (myObserver) {
			formatResourceStringDef(msg, RESID_CYNCHRONIZE_RECORD, "Record %d/%d", i+1, status.currentRows);
			[myObserver setCaption2: msg];
		}
    //************************* logcoment
//		doLog(0,"CimBackup -> Creando reg %d de %ld\n", i+1, status.currentRows);

		[SafeBoxHAL fsRead: fileId numRows: 1 unitSize: [sourceTable getRecordSize] buffer: aux];
		field = [sourceTable getAutoIncField];
		if (field != NULL && !initialized) {
			initialized = TRUE;
			autoIncValue = [self getValue: field buffer: aux];
			if (autoIncValue <= 0) autoIncValue = 0;
			else autoIncValue--;
			[aDestRS setInitialAutoIncValue: autoIncValue];
            //************************* logcoment
			//doLog(0,"CimBackup -> valor autoincremental inicial = %ld\n", autoIncValue);
		}
		
		[aDestRS add];
		[aDestRS setRecordBuffer: aux];
		[aDestRS save];

	}
}

/**/
- (unsigned long) getLastRowValue: (char *) aTableName field: (char *) aFieldName
{
	char buf[255];
	char fileName[255];
	unsigned long lvalue = 0;
	Field *field;
	TABLE table;
	int fileId;
	SafeBoxFileStatus status;

#ifdef DISABLE_CIM_BACKUP
	return 0;
#endif
	if ([SafeBoxHAL getHardwareSystemStatus] == HardwareSystemStatus_SECONDARY) return 0;

	sprintf(fileName, "%s_bck", aTableName);
	
	table = [[DB getInstance] getTable: fileName];
	fileId = [table getFileId];

	field = [table getField: aFieldName];

	// Leo el ultimo registro del archivo backup
	[SafeBoxHAL fsStatus: fileId status: &status];

	if (status.currentRows == 0) return 0;

	[SafeBoxHAL fsSeek: fileId offset: -1 whence: SEEK_END];
	if ([SafeBoxHAL fsRead: fileId numRows: 1 unitSize: [table getRecordSize] buffer: buf] != 1) THROW_MSG(GENERAL_IO_EX, aTableName);
	
	lvalue = [self getValue: field buffer: buf];

	return lvalue;
}

/**
 * Limpia todas las tablas de transactions de la placa
 */
- (void) reinitTransactionsBackupFiles
{

	if (!myBackupCanceled) {
		if (mySplashBackup) {
			[mySplashBackup updateDisplay: 10 msg: getResourceStringDef(RESID_CLEAN_BACKUP_TABLE, "Cleaning table ...")];
			[mySplashBackup setLabel2: "audits ..."];
		}
		[SafeBoxHAL fsReInitFile: 1]; // borra las auditorias

		myLastAuditId = 0;
		[[[Persistence getInstance] getBackupsDAO] store: self];
	}

	if (!myBackupCanceled) {
		if (mySplashBackup) {
			[mySplashBackup updateDisplay: 30 msg: getResourceStringDef(RESID_CLEAN_BACKUP_TABLE, "Cleaning table ...")];
			[mySplashBackup setLabel2: "audit details ..."];
		}
		[SafeBoxHAL fsReInitFile: 2]; // borra los detalles de auditorias

		myLastAuditDetailId = 0;
		[[[Persistence getInstance] getBackupsDAO] store: self];
	}

	if (!myBackupCanceled) {
		if (mySplashBackup) {
			[mySplashBackup updateDisplay: 45 msg: getResourceStringDef(RESID_CLEAN_BACKUP_TABLE, "Cleaning table ...")];
			[mySplashBackup setLabel2: "drops ..."];
		}
		[SafeBoxHAL fsReInitFile: 3]; // borra los depositos

		myLastDropId = 0;
		[[[Persistence getInstance] getBackupsDAO] store: self];
	}

	if (!myBackupCanceled) {
		if (mySplashBackup) {
			[mySplashBackup updateDisplay: 68 msg: getResourceStringDef(RESID_CLEAN_BACKUP_TABLE, "Cleaning table ...")];
			[mySplashBackup setLabel2: "drop details ..."];
		}
		[SafeBoxHAL fsReInitFile: 4]; // borra los detalles de depositos

		myLastDropDetailId = 0;
		[[[Persistence getInstance] getBackupsDAO] store: self];
	}

	if (!myBackupCanceled) {
		if (mySplashBackup) {
			[mySplashBackup updateDisplay: 79 msg: getResourceStringDef(RESID_CLEAN_BACKUP_TABLE, "Cleaning table ...")];
			[mySplashBackup setLabel2: "deposits ..."];
		}
		[SafeBoxHAL fsReInitFile: 5]; // borra las extracciones

		myLastDepositId = 0;
		[[[Persistence getInstance] getBackupsDAO] store: self];
	}

	if (!myBackupCanceled) {
		if (mySplashBackup) {
			[mySplashBackup updateDisplay: 87 msg: getResourceStringDef(RESID_CLEAN_BACKUP_TABLE, "Cleaning table ...")];
			[mySplashBackup setLabel2: "deposit details ..."];
		}
		[SafeBoxHAL fsReInitFile: 6]; // borra los detalles de extracciones

		myLastDepositDetailId = 0;
		[[[Persistence getInstance] getBackupsDAO] store: self];
	}

	if (!myBackupCanceled) {
		if (mySplashBackup) {
			[mySplashBackup updateDisplay: 96 msg: getResourceStringDef(RESID_CLEAN_BACKUP_TABLE, "Cleaning table ...")];
			[mySplashBackup setLabel2: "zcloses ..."];
		}
		[SafeBoxHAL fsReInitFile: 7]; // borra los cierres Z

		myLastZcloseId = 0;
		[[[Persistence getInstance] getBackupsDAO] store: self];
	}

}

/**
 * Cincroniza todas las tablas de transactions del CT8016 a la placa
 */
- (void) syncTransactionsBackupFiles
{
	char msg[50];
	char buf[200];

#ifdef DISABLE_CIM_BACKUP
	return;
#endif

    //*********************logcoment
//	doLog(0,"CimBackup -> syncTransactionsBackupFiles\n");	

	TRY
		myFinishWithError = FALSE;

		if (!myBackupCanceled) {
			if (mySplashBackup) {
				formatResourceStringDef(msg, RESID_CYNCHRONIZE_TABLE, "Sync %s ...", "audits");
				myCurrentBackupTablesCount += myValueToIncBackupTables;
				[mySplashBackup updateDisplay: myCurrentBackupTablesCount msg: msg];
			}
			[self syncFile: "audits" sourceRS: myAuditsRS];
		}
	
		if (!myBackupCanceled) {
			if (mySplashBackup) {
				formatResourceStringDef(msg, RESID_CYNCHRONIZE_TABLE, "Sync %s ...", "audit details");
				myCurrentBackupTablesCount += myValueToIncBackupTables;
				[mySplashBackup updateDisplay: myCurrentBackupTablesCount msg: msg];
			}
			[self syncFile: "change_log" sourceRS: myChangeLogRS];
		}
	
		if (!myBackupCanceled) {
			if (mySplashBackup) {
				formatResourceStringDef(msg, RESID_CYNCHRONIZE_TABLE, "Sync %s ...", "drops");
				myCurrentBackupTablesCount += myValueToIncBackupTables;
				[mySplashBackup updateDisplay: myCurrentBackupTablesCount msg: msg];
			}
			[self syncFile: "deposits" sourceRS: myDepositsRS];
		}
	
		if (!myBackupCanceled) {
			if (mySplashBackup) {
				formatResourceStringDef(msg, RESID_CYNCHRONIZE_TABLE, "Sync %s ...", "drop details");
				myCurrentBackupTablesCount += myValueToIncBackupTables;
				[mySplashBackup updateDisplay: myCurrentBackupTablesCount msg: msg];
			}
			[self syncFile: "deposit_details" sourceRS: myDepositsDetailsRS];
		}
	
		if (!myBackupCanceled) {
			if (mySplashBackup) {
				formatResourceStringDef(msg, RESID_CYNCHRONIZE_TABLE, "Sync %s ...", "deposits");
				myCurrentBackupTablesCount += myValueToIncBackupTables;
				[mySplashBackup updateDisplay: myCurrentBackupTablesCount msg: msg];
			}
			[self syncFile: "extractions" sourceRS: myExtractionsRS];
		}
	
		if (!myBackupCanceled) {
			if (mySplashBackup) {
				formatResourceStringDef(msg, RESID_CYNCHRONIZE_TABLE, "Sync %s ...", "deposit details");
				myCurrentBackupTablesCount += myValueToIncBackupTables;
				[mySplashBackup updateDisplay: myCurrentBackupTablesCount msg: msg];
			}
			[self syncFile: "extraction_details" sourceRS: myExtractionsDetailsRS];
		}
	
		if (!myBackupCanceled) {
			if (mySplashBackup) {
				formatResourceStringDef(msg, RESID_CYNCHRONIZE_TABLE, "Sync %s ...", "zcloses");
				myCurrentBackupTablesCount += myValueToIncBackupTables;
				[mySplashBackup updateDisplay: myCurrentBackupTablesCount msg: msg];
			}
			[self syncFile: "zclose" sourceRS: myZCloseRS];
		}
	
		// almaceno los ultimos ids de transacciones hasta donde haya legado
		[self saveTransBackupIds];
	
		// guardo la fecha de backup de transacciones solo si no cancelo
		if (!myBackupCanceled) {
			[self saveTransBackupDate];
	
			if (mySplashBackup) [mySplashBackup updateDisplay: 100 msg: getResourceStringDef(RESID_BACKUP_COMPLETE, "BackUp Complete ...")];
		}
	
		// inicializo nuevamente la variable
		myBackupCanceled = FALSE;

	CATCH

		myFinishWithError = TRUE;

		// audito error
		[Audit auditEventCurrentUser: Event_BACKUP_ERROR additional: "" station: 0 logRemoteSystem: FALSE];
        //************************* logcoment
		//doLog(0,"BackUp Finalizado con ERROR\n");

		if (!myIsAutomaticBackup) {
			// muestro advertencia
			strcpy(buf,getResourceStringDef(RESID_BACKUP_TABLE_ERROR, "Error en backup. Se sugiere ejecutar Backup-Completo"));
			[UICimUtils showAlarm: buf];
		}

	END_TRY
}

/**/
- (void) syncSettingsBackupFiles
{
  COLLECTION tables;
  int i;
  TABLE table;
	char fromTableName[50];
	BOOL copyTable;
	STRING_TOKENIZER tokenizer = [StringTokenizer new];
	char msg[50];
	char buf[200];

	if (myCurrentBackupType == BackupType_UNDEFINED) return;

	TRY

		myFinishWithError = FALSE;
		copyTable = TRUE;
		tables = [[DB getInstance] getTables];
	
		[tokenizer setDelimiter: "_bck"];
		[tokenizer setTrimMode: TRIM_ALL];
    //*********************logcoment
	
/*		if (myCurrentBackupType == BackupType_SETTINGS)
			doLog(0,"CimBackup -> syncSettingsBackupFiles: [SETTINGS]\n");
		else if (myCurrentBackupType == BackupType_USERS)
					doLog(0,"CimBackup -> syncSettingsBackupFiles: [USERS]\n");
				else if (myCurrentBackupType == BackupType_ALL)
								doLog(0,"CimBackup -> syncSettingsBackupFiles: [ALL]\n");
	*/
		for (i = 0; i < [tables size]; ++i) {
	
			// si se cancelo el backup entonces aborto del proceso
			if (myBackupCanceled) break;
	
			table = [tables at: i];
	
			// obtengo el nombre de la tabla y le quito el "_bck" del final
			[tokenizer restart];
			[tokenizer setText: [table getName]];
			if ([tokenizer hasMoreTokens]) 
				[tokenizer getNextToken: fromTableName];
	
			// copiar el archivo a la placa    
			if ([table getFileId] == 0) {
	
				if (myCurrentBackupType != BackupType_ALL) {
					if (myCurrentBackupType == BackupType_SETTINGS) {
						copyTable = TRUE;
						// solo copio tablas de settings
						if ( (strcmp(fromTableName,"doors_by_user") == 0) ||
								(strcmp(fromTableName,"users") == 0) ||
								(strcmp(fromTableName,"profiles") == 0) ||
								(strcmp(fromTableName,"dual_access") == 0) ) copyTable = FALSE;
					} else if (myCurrentBackupType == BackupType_USERS) {
						copyTable = FALSE;
						// solo copio tablas de usuarios
						if ( (strcmp(fromTableName,"doors_by_user") == 0) ||
								(strcmp(fromTableName,"users") == 0) ||
								(strcmp(fromTableName,"profiles") == 0) ||
								(strcmp(fromTableName,"dual_access") == 0) ) copyTable = TRUE;
					}
				} else copyTable = TRUE; // copio todas las tablas
	
				/*TODO: analizar si es conveniente hacer un clearFile = TRUE o no*/
				if (copyTable) {
					if (!myBackupCanceled) {
						if (mySplashBackup) {
							formatResourceStringDef(msg, RESID_CYNCHRONIZE_TABLE, "Sync %s ...", fromTableName);
							myCurrentBackupTablesCount += myValueToIncBackupTables;
							// esto lo hago por una cuestion visual, para que en la ultima tabla no muestre
							// 100 % ya que aun queda copiar todos los registros de la misma.
							if (myCurrentBackupTablesCount == 100) 
								myCurrentBackupTablesCount--;
							[mySplashBackup updateDisplay: myCurrentBackupTablesCount msg: msg];
						}
						[self copyBackupFile: table path: DATA_FILES_PATH clearFile: FALSE deleteAfterCopy: FALSE fromFile: fromTableName];
					}
				}
	
			} // if
		} // for
		[tokenizer free];
	
		if (!myBackupCanceled) {
			// almaceno la fecha/hora en la que se realizo el backup de settings
			if ((myCurrentBackupType == BackupType_SETTINGS) || (myCurrentBackupType == BackupType_ALL))
				[self saveSettBackupValues];
			// almaceno la fecha/hora en la que se realizo el backup de usuarios
			if ((myCurrentBackupType == BackupType_USERS) || (myCurrentBackupType == BackupType_ALL))
				[self saveUserBackupValues];
			
			if (mySplashBackup) [mySplashBackup updateDisplay: 100 msg: getResourceStringDef(RESID_BACKUP_COMPLETE, "BackUp Complete ...")];
		}

	CATCH

		myFinishWithError = TRUE;

		// audito error
		[Audit auditEventCurrentUser: Event_BACKUP_ERROR additional: "" station: 0 logRemoteSystem: FALSE];
        //************************* logcoment
		//doLog(0,"BackUp Finalizado con ERROR\n");

		if (!myIsAutomaticBackup) {
			// muestro advertencia
			strcpy(buf,getResourceStringDef(RESID_BACKUP_TABLE_ERROR, "Error en backup. Se sugiere ejecutar Backup-Completo"));
			[UICimUtils showAlarm: buf];
		}

	END_TRY
}

/**/
- (void) syncBackupFiles
{

#ifdef DISABLE_CIM_BACKUP
	return;
#endif

	[self syncFile: "audits" sourceRS: myAuditsRS];
	[self syncFile: "change_log" sourceRS: myChangeLogRS];
	[self syncFile: "deposits" sourceRS: myDepositsRS];
	[self syncFile: "deposit_details" sourceRS: myDepositsDetailsRS];
	[self syncFile: "extractions" sourceRS: myExtractionsRS];
	[self syncFile: "extraction_details" sourceRS: myExtractionsDetailsRS];
	[self syncFile: "zclose" sourceRS: myZCloseRS];

}

/**/
- (void) setTerminated: (BOOL) aTerminated
{
	myTerminated = aTerminated;
}

/**/
- (void) beginCriticalRestoreSection: (char*) aTableName
{
	char fileName[200];
	FILE *f;

	// creo un archivo critico con el nombre de la tabla actual
	strcpy(fileName, aTableName);
	f = fopen(fileName, "w+");
	fclose(f);
}

/**/
- (void) endCriticalRestoreSection: (char*) aTableName
{
	char fileName[200];

	strcpy(fileName, aTableName);
	unlink(fileName);
}

/** indica si existe el archivo critico de restore de la tabla */
- (BOOL) existCriticalRestoreFile: (char*) aTableName
{
	FILE *f;
	char fileName[200];
	
	strcpy(fileName, aTableName);

	// verifico si existe el nombre del archivo
	f = fopen(fileName, "r");
	if (!f) return FALSE;

	fclose(f);
	
	return TRUE;
}

/**/
- (void) beginBackupTransactions
{
	char fileName[200];
	FILE *f;

	// creo un archivo temporal para indicar que el backup comenzo.
	// al finalizar el backup dicho archivo debe ser eliminado
	strcpy(fileName, BACKUP_FILE_NAME);

	f = fopen(fileName, "w+");
	fprintf(f, "/* Backupeando data */");
	fclose(f);

	// por las dudas elimino el archivo de que estoy en backup manualmente
	strcpy(fileName, BACKUP_MANUAL_FILE_NAME);
	unlink(fileName);

}

- (void) beginBackupManualTrans
{
	char fileName[200];
	FILE *f;

	// creo un archivo temporal para indicar que el backup manual comenzo.
	// al finalizar el backup dicho archivo debe ser eliminado
	strcpy(fileName, BACKUP_MANUAL_FILE_NAME);

	f = fopen(fileName, "w+");
	fprintf(f, "/* Backupeando data manual */");
	fclose(f);

}

/**/
- (void) endBackupTransactions
{
	char fileName[200];

	// elimino el archivo de que estoy en backup manualmente
	strcpy(fileName, BACKUP_MANUAL_FILE_NAME);
	unlink(fileName);
	
	// elimino el archivo de que estoy en backup
	strcpy(fileName, BACKUP_FILE_NAME);
	unlink(fileName);
}

/**/
- (BOOL) isBackupTransactionsFailure
{
	FILE *f;
	char fileName[200];
	
	strcpy(fileName, BACKUP_FILE_NAME);
	f = fopen(fileName, "r");
	if (!f) return FALSE;

	fclose(f);
	
	return TRUE;
}

/**/
- (BOOL) isBackupManualTransFailure
{
	FILE *f;
	char fileName[200];
	
	strcpy(fileName, BACKUP_MANUAL_FILE_NAME);
	f = fopen(fileName, "r");
	if (!f) return FALSE;

	fclose(f);
	
	return TRUE;
}

/**/
- (void) beginRestore
{
	char fileName[200];
	FILE *f;

	// creo un archivo temporal para indicar que el restore comenzo.
	// al finalizar el restore dicho archivo debe ser eliminado
	strcpy(fileName, RESTORE_FILE_NAME);

    //************************* logcoment
   //doLog(0,"INICIO DE RESTORE\n");

	f = fopen(fileName, "w+");
	fprintf(f, "/* Restaurando data */");
	fclose(f);

	// creo un archivo temporal para saber si debo auditar el error en
	// el restore
	strcpy(fileName, RESTORE_FILE_NAME_ERROR);
	f = fopen(fileName, "w+");
	fprintf(f, "/* Auditar error en restore */");
	fclose(f);

	myInRestore = TRUE;
}


/**/
- (void) endRestore
{
	FILE *f;
	char fileName[200];
	
	strcpy(fileName, RESTORE_FILE_NAME);

	// elimino el archivo de que estoy en restore
    //************************* logcoment
	//doLog(0,"FIN DE RESTORE\n");
	unlink(fileName);

	// elimino el archivo de que el restore finalizo con error
	// este archivo sirve para que al inicio de la aplicacion se pueda auditar
	// que el restore termino erroneo
	strcpy(fileName, RESTORE_FILE_NAME_ERROR);
	unlink(fileName);

	// creo el archivo de que el restore finalizo ok
	// este archivo sirve para que al inicio de la aplicacion se pueda auditar
	// que el restore fue aplicado
	strcpy(fileName, RESTORE_FILE_NAME_OK);
	f = fopen(fileName, "w+");
	fprintf(f, "/* Restauracion OK */");
	fclose(f);

	myInRestore = FALSE;
}

/**/
- (BOOL) inRestore
{
	return myInRestore;
}

/**/
- (BOOL) isRestoreFailure
{
	FILE *f;
	char fileName[200];
	
	strcpy(fileName, RESTORE_FILE_NAME);
	f = fopen(fileName, "r");
	if (!f) return FALSE;

	fclose(f);
	
	return TRUE;
}

/**/
- (BOOL) shouldAuditRestoreError
{
	FILE *f;
	char fileName[200];
	
	strcpy(fileName, RESTORE_FILE_NAME_ERROR);
	f = fopen(fileName, "r");
	if (!f) return FALSE;

	fclose(f);

	// elimino el archivo de error para que no se vuelva a auditar
	unlink(fileName);

	return TRUE;
}

/**/
- (BOOL) isRestoreOk
{
	FILE *f;
	char fileName[200];
	
	strcpy(fileName, RESTORE_FILE_NAME_OK);
	f = fopen(fileName, "r");
	if (!f) return FALSE;

	fclose(f);

	// elimino el archivo de que el restore salio ok
	unlink(fileName);
	
	return TRUE;
}

/**/
- (ABSTRACT_RECORDSET) getRecordSetFromTable: (char*) aTableName
{

	if (strcmp(aTableName, "audits") == 0) return myAuditsRS;
	if (strcmp(aTableName, "change_log") == 0) return myChangeLogRS;
	if (strcmp(aTableName, "deposits") == 0) return myDepositsRS;
	if (strcmp(aTableName, "deposit_details") == 0) return myDepositsDetailsRS;
	if (strcmp(aTableName, "extractions") == 0) return myExtractionsRS;
	if (strcmp(aTableName, "extraction_details") == 0) return myExtractionsDetailsRS;
	if (strcmp(aTableName, "zclose") == 0) return myZCloseRS;	

	return NULL;
}

/**/
- (void) syncFilesCollection
{
	int i;
	SyncFileStruct* syncfStruct;
	ABSTRACT_RECORDSET rs;
	BOOL hasToSyncFile = FALSE;
	BOOL error;

	for (i=0; i<[mySyncFilesCollection size]; ++i) {
		syncfStruct = (SyncFileStruct*) [mySyncFilesCollection at: i];

		[myMutex lock];
		hasToSyncFile = syncfStruct->syncFileFlag;
		[myMutex unLock];

		if (hasToSyncFile) {

			//doLog ("CimBackup -> Sync file table name: %s - Sync: %d  \n", syncfStruct->tableName, syncfStruct->syncFileFlag);

			rs = [self getRecordSetFromTable: syncfStruct->tableName];
			[rs moveNext];

			while (![rs eof]) {

				error = TRUE;

				while (error) {

					if ([[CimManager getInstance] isSystemIdleForSyncFiles]) {

							TRY
							[self doSyncRecord: syncfStruct->tableName buffer: [rs getRecordBuffer]];
							error = FALSE;
						CATCH
							ex_printfmt();
						END_TRY
					} else {
                        //************************* logcoment
						//doLog(0,"CimBackup -> Inhabilitado para sincronizar\n");
						[rs movePrev];
						return;
					}

				}

				[rs moveNext];

			}

			[rs movePrev];

			[self setSyncFileFlag: syncfStruct value: FALSE];

			if (![self existFilesToSync]) [self setHasToSync: FALSE];

		}
	
	}

}

/**/
- (void) run
{
	int backupTime;
	int backupFrame;
	int current;
	struct tm currentBrokenTime;
	struct tm lastBackupBrokenTime;
	JFORM splashBackupForm;
	JWINDOW myOldForm;
	char additional[100];
	char buf[200];

    //************************* logcoment
	//doLog(0,"Iniciando hilo de backup automatico...\n");

	while (!myTerminated) {

		msleep(BACKUP_TIME);

		// Si tengo configurado el backup automatico en FALSE
		if (![[CimGeneralSettings getInstance] isAutomaticBackup]) continue;

		// si estoy en proceso de restore
		if ([self inRestore]) continue;

		// solo se lanzara el backup automatico si estoy en la pantalla de login
		// se agrega el TRY porque en ocaciones el metodo isKindOf tira error
		TRY
			if ([JWindow getActiveWindow] != NULL && 
					![[JWindow getActiveWindow] isKindOf: [JUserLoginForm class]]) {
        EXIT_TRY;
				continue;
			}
		CATCH
			 continue;
		END_TRY
	
		// Verifico que el sistema este idle
		if (![[CimManager getInstance] isSystemIdleForSyncFiles]) continue;
	
		backupTime = [[CimGeneralSettings getInstance] getBackupTime];
		backupFrame = [[CimGeneralSettings getInstance] getBackupFrame];
	
		// Verifica si llego al tiempo seteado
		[SystemTime decodeTime: [SystemTime getLocalTime] brokenTime: &currentBrokenTime];
		current = currentBrokenTime.tm_hour * 60 + currentBrokenTime.tm_min;
		if (current < backupTime) continue;
	
		// si la hora actual es mayor que la hora + marco de espera me voy
		if (current > (backupTime + backupFrame)) continue;

		// Este control es para que el backup no se ejecute el mismo dia mas de una vez		
		[SystemTime decodeTime: myBackupTransDate brokenTime: &lastBackupBrokenTime];
		if ((currentBrokenTime.tm_year == lastBackupBrokenTime.tm_year) && 
			  (currentBrokenTime.tm_mon  == lastBackupBrokenTime.tm_mon) && 
			  (currentBrokenTime.tm_mday == lastBackupBrokenTime.tm_mday)) continue;

		// Genero el backup automatico
		myIsAutomaticBackup = TRUE;
		myOldForm = [JWindow getActiveWindow];
		if (myOldForm) [myOldForm deactivateWindow];

		splashBackupForm = [JSplashBackupForm createForm: NULL];
	
		[splashBackupForm refreshScreen];
		[splashBackupForm setReinitFiles: FALSE];
		[splashBackupForm setBackupType: BackupType_TRANSACTIONS];
		[splashBackupForm setCanCancel: FALSE];
		[splashBackupForm setRunBackupProgress: FALSE];
		[[InputKeyboardManager getInstance] setIgnoreKeyEvents: TRUE];
		[splashBackupForm showForm];

		// inicializo variables
		[self setSplashBackup: splashBackupForm];
		[self setBackupCanceled: FALSE];

		// indico el comienzo del backup de transacciones
		[self beginBackupTransactions];
		[self beginBackupManualTrans];

		// audito el comienzo del backup
		strcpy(additional, getResourceStringDef(RESID_BCK_TYPE_AUTOMATIC_DESC, "Automatic"));
		[Audit auditEventCurrentUser: Event_BACKUP_STARTED additional: additional station: 0 logRemoteSystem: FALSE];

		// ejecuto proceso de backup
		[self setCurrentBackupType: BackupType_TRANSACTIONS];
		[self syncTransactionsBackupFiles];

		// audito la finalizacion del backup solo si NO fue cancelado
		if (!myBackupCanceled) {
			if (!myFinishWithError) {

				// indico el fin del backup de transacciones
				[self endBackupTransactions];

				[Audit auditEventCurrentUser: Event_BACKUP_FINISHED additional: "" station: 0 logRemoteSystem: FALSE];
                //************************* logcoment
				//doLog(0,"BackUp Finalizado\n");
			}
		}

		// inicializo variables
		[self setCurrentBackupType: BackupType_UNDEFINED];
		[self setSplashBackup: NULL];
		[self setBackupCanceled: FALSE];

		// cierro formulario
		[splashBackupForm closeForm];
		[[InputKeyboardManager getInstance] setIgnoreKeyEvents: FALSE];
		[splashBackupForm free];
		if (myOldForm) [myOldForm activateWindow];

		// si el backup automatico termino con error muestro mensaje
		if (myFinishWithError) {
			myFinishWithError = FALSE;
			// muestro advertencia
			strcpy(buf,getResourceStringDef(RESID_BACKUP_TABLE_ERROR, "Error en backup. Se sugiere ejecutar Backup-Completo"));
			[UICimUtils showAlarm: buf];
		}

		myIsAutomaticBackup = FALSE;

	}
	myIsAutomaticBackup = FALSE;
	myFinishWithError = FALSE;

}

/**/
/*- (void) run
{

	while (!myTerminated) {
		if (![self hasToSync]) {
			//doLog(0,"No debe sincronizar ningun archivo \n");
			msleep(500);
			continue;
		}

		// verifica que pueda sincronizar
		if (![[CimManager getInstance] isSystemIdleForSyncFiles]) {
			msleep(500);
			continue;
		}

		//doLog(0,"Sincroniza\n");
		[self syncFilesCollection];
		msleep(100);

	}
}*/


/**/
- (void) setLastAuditId: (int) aValue { myLastAuditId = aValue; }
- (int) getLastAuditId { return myLastAuditId; }

- (void) setLastAuditDetailId: (int) aValue { myLastAuditDetailId = aValue; }
- (int) getLastAuditDetailId { return myLastAuditDetailId; }

- (void) setLastDropId: (int) aValue { myLastDropId = aValue; }
- (int) getLastDropId { return myLastDropId; }

- (void) setLastDropDetailId: (int) aValue { myLastDropDetailId = aValue; }
- (int) getLastDropDetailId { return myLastDropDetailId; }

- (void) setLastDepositId: (int) aValue { myLastDepositId = aValue; }
- (int) getLastDepositId { return myLastDepositId; }

- (void) setLastDepositDetailId: (int) aValue { myLastDepositDetailId = aValue; }
- (int) getLastDepositDetailId { return myLastDepositDetailId; }

- (void) setLastZcloseId: (int) aValue { myLastZcloseId = aValue; }
- (int) getLastZcloseId { return myLastZcloseId; }

- (void) setBackupTransDate: (datetime_t) aValue { myBackupTransDate = aValue; }
- (datetime_t) getBackupTransDate { return myBackupTransDate; }

- (void) setBackupSettDate: (datetime_t) aValue { myBackupSettDate = aValue; }
- (datetime_t) getBackupSettDate { return myBackupSettDate; }

- (void) setBackupUserDate: (datetime_t) aValue { myBackupUserDate = aValue; }
- (datetime_t) getBackupUserDate { return myBackupUserDate; }

- (void) setTableCheckList: (unsigned char*) aValue { memcpy(myTableCheckList, aValue, 14); }
- (unsigned char*) getTableCheckList { return myTableCheckList; }

- (void) initBackupTable
{
	TRY
		myLastAuditId = 0;
		myLastAuditDetailId = 0;
		myLastDropId = 0;
		myLastDropDetailId = 0;
		myLastDepositId = 0;
		myLastDepositDetailId = 0;
		myLastZcloseId = 0;
		myBackupTransDate = 0;
		myBackupSettDate = 0;
		myBackupUserDate = 0;
		memset(myTableCheckList, 0, 14);
	
		[[[Persistence getInstance] getBackupsDAO] loadById: 1 cimBackup: self];
	CATCH

	END_TRY;

}

/**/
- (void) initTransBackupTableCheck
{
	memset(myTableCheckList, 0, 14);

	TRY
		[[[Persistence getInstance] getBackupsDAO] store: self];
	CATCH

		[self initBackupTable];

	END_TRY
}

/**/
- (void) saveTransBackupDate
{
	myBackupTransDate = [SystemTime getLocalTime];

	TRY
		[[[Persistence getInstance] getBackupsDAO] store: self];
	CATCH

		[self initBackupTable];

	END_TRY
}

/**/
- (void) saveTransBackupIds
{
	TRY

		myLastAuditId = [self getLastRowValue: "audits" field: "AUDIT_ID"];
		myLastAuditDetailId = [self getLastRowValue: "change_log" field: "AUDIT_ID"];
		myLastDropId = [self getLastRowValue: "deposits" field: "NUMBER"];
		myLastDropDetailId = [self getLastRowValue: "deposit_details" field: "NUMBER"];
		myLastDepositId = [self getLastRowValue: "extractions" field: "NUMBER"];
		myLastDepositDetailId = [self getLastRowValue: "extraction_details" field: "NUMBER"];
		myLastZcloseId = [self getLastRowValue: "zclose" field: "NUMBER"];
	
		[[[Persistence getInstance] getBackupsDAO] store: self];

	CATCH

		[self initBackupTable];

	END_TRY
}

/**/
- (void) saveSettBackupValues
{
	myBackupSettDate = [SystemTime getLocalTime];

	TRY
		[[[Persistence getInstance] getBackupsDAO] store: self];
	CATCH

		[self initBackupTable];

	END_TRY
}

/**/
- (void) saveUserBackupValues
{
	myBackupUserDate = [SystemTime getLocalTime];

	TRY
		[[[Persistence getInstance] getBackupsDAO] store: self];
	CATCH

		[self initBackupTable];

	END_TRY
}

/**/
- (void) checkTable: (id) aTable bitValue: (int) aBitValue
{
	int order, fileId;

	fileId = [aTable getFileId];
	order = [aTable getTableOrder];

	if (fileId != 0) return;
	if (order == 0) return;

	TRY
		setbit(myTableCheckList, order, aBitValue);
		[[[Persistence getInstance] getBackupsDAO] store: self];
	CATCH

		[self initBackupTable];

	END_TRY

	/*doLog(0,"\n");
	doLog(0,"order [%d] bitValue [%d]\n",order,aBitValue);
	for (j=1; j<= 24; ++j) {
		doLog(0,"%d",getbit(myTableCheckList, j));
	}
	doLog(0,"\n");*/
}

/**/
- (BOOL) isCheckTablesOk
{
	int i,j;
	COLLECTION tables;
	TABLE table;
	int order, fileId;
	char tableName[50];

	mySuggestedBackup = BackupType_UNDEFINED;

	tables = [[DB getInstance] getTables];

    //************************* logcoment
    //doLog(0,"\n");
	for (j=1; j<= 24; ++j) {
        //************************* logcoment
		//doLog(0,"%d",getbit(myTableCheckList, j));
	}
    //************************* logcoment
	//doLog(0,"\n");

	for (i = 0; i < [tables size]; ++i) {
		table = [tables at: i];
		fileId = [table getFileId];
		order = [table getTableOrder];
		strcpy(tableName, [table getName]);

		if (fileId == 0) {
			if (order > 0) {
				if (getbit(myTableCheckList, order) == 1) {
                    //************************* logcoment
					//doLog(0,"tabla [%d][%s] incompleta ***************\n",order,tableName);

					// marco que tipo de tabla es la que esta rota para sugerir el backup correspondiente
					if ( (strcmp(tableName,"doors_by_user_bck") == 0) ||
							(strcmp(tableName,"users_bck") == 0) ||
							(strcmp(tableName,"profiles_bck") == 0) ||
							(strcmp(tableName,"dual_access_bck") == 0) ) {
								mySuggestedBackup = BackupType_USERS;
					} else mySuggestedBackup = BackupType_SETTINGS;

					return FALSE;
				}
			}
		}
	}

	return TRUE;
}

/**/
- (id) isCheckTableOk: (char *) aTableName
{
	TABLE table = NULL;

	table = [[DB getInstance] getTable: aTableName];

	if (!table) return NULL;
	if ([table getFileId] != 0) return NULL;
	if ([table getTableOrder] == 0) return NULL;

	if (getbit(myTableCheckList, [table getTableOrder]) == 0) return table;

 	return NULL;

}

@end
