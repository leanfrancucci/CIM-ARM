#include "SupportThread.h"
#include "AbstractAcceptor.h"
#include "CimManager.h"
#include "system/util/all.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "TemplateParser.h"
#include "UserManager.h"
#include <unistd.h>
#include <dirent.h>
#include <stdio.h>
#include "TelesupScheduler.h"
#include "TelesupervisionManager.h"

#define SUPPORT_CHECK_TIME			10000		// 60 segundos


/**/
@implementation SupportThread

static SUPPORT_THREAD singleInstance = NULL; 


- (BOOL) unzipFile: (char *) aFileName;
/*
- (BOOL) unzipInnerBoardFile: (char *) aFileName;
- (void) setIniFileInfo: (char *) anAcceptorSettingIdList fileName: (char *) aFileName;
*/


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
    myTaskInProgress = FALSE;
    
	/**myCurrentFile = '\0';
	myUpgradeInProgress = FALSE;
	myCanDeleteUpgrade = TRUE;*/
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
/*
- (BOOL) isUpgradeInProgress
{
	return myUpgradeInProgress;
}
*/


/**/
- (void) startTask: (char*) aFileName
{
	char command[100];
    int result = 0;
    
    printf("*********************************************************\n");
    printf("comienza la ejecucion de la tarea\n");
    printf("*********************************************************\n");
	myTaskInProgress = TRUE;

	//myUpgradeIsFinish = FALSE;
	//myUpgradeIsSuccess = FALSE;

										
	printf("Descomprimiendo archivo %s\n", aFileName);

	if ([self unzipFile: aFileName]) {
		printf("Pudo descomprimir el archivo\n");
	} else {
		return;
	}

	myCanDeleteTask = TRUE;

/*    sprintf(command, "cd %s/unzip", SUPPORT_PATH);
    result = system(command);          
    
    printf("Comando ejecutado %s, resultado = %d\n", command, result);
*/    
    sprintf(command, "sh %s/unzip/%s", SUPPORT_PATH, "runsupport.sh");
    result = system(command);             
    
    printf("Comando ejecutado %s, resultado = %d\n", command, result);

}


/**/
- (void) stopTask
{
	myTaskInProgress= FALSE;
}


/**/

- (BOOL) unzipFile: (char *) aFileName
{
	char command[512];
	int result = 0;


	/*sprintf(command, "mkdir %s/unzip", SUPPORT_PATH);
	result = system(command);*/
    
    printf("Ejecutando comando %s, resultado = %d\n", command, result);
	//if (result != 0) return FALSE;

/*	sprintf(command, "gunzip -c %s/%s 2> /dev/null | tar -xvf - -C %s/unzip/ 2> /dev/null", SUPPORT_PATH,
		aFileName, SUPPORT_PATH);
*/

    //tar -cvf support1.tar runsupport.sh
    sprintf(command, "tar -xvf %s/%s -C %s/unzip/ 2> /dev/null", SUPPORT_PATH,
		aFileName, SUPPORT_PATH);
        
 	printf("Ejecutando comando %s\n", command);
	result = system(command);
    
	printf("Comando ejecutado %s, resultado = %d\n", command, result);
	if (result != 0) return FALSE;

	return TRUE;
}

- (void) checkResult
{
    DIR *dir;
    struct dirent *dp;
    BOOL hasFiles = FALSE;
    char path[100];
    char command[500];
    id telesup;
    
    sprintf(path, "%s/out", SUPPORT_PATH);
    
    printf("Try to opendir |%s|\n", path);
    dir = opendir (path);

    
    if (dir == NULL) {
        printf("No pudo abrir el directorio\n");
        return;
    }  
 
    
    while ((dp = readdir (dir)) != NULL) {
        //existen archivos
        
        printf("hay archivos en out\n");
        hasFiles = TRUE;
        break;
    }
    
    closedir (dir);
    
    //si existen archivos comprimo en un tar y debo enviarlo a la PIMS
    if (hasFiles) {
        sprintf(command, "tar -cvf %s/outsupport.tar %s/out/%s", SUPPORT_PATH, SUPPORT_PATH, "*");
        //tar -cvf /rw/CT8016/support/out.tar /rw/CT8016/support/out/
        system(command);
        
        telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

        if( telesup ) printf("HAY supervision PIMS\n");
        
		if ( telesup ) {
            if( telesup ) printf("SUPERVISA PIMS\n");
			//doLog(0,"Supervisa tarea de soporte\n");
	
			[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_SUPPORT_TASK];
			[[TelesupScheduler getInstance] startTelesupInBackground];
		}
        
        // si superviso con exito deberia borrar el archivo .tar
        while ([[TelesupScheduler getInstance] inTelesup]) msleep(10);
        
        sprintf(command, "rm * /rw/CT8016/support/out");
        system(command);

        sprintf(command, "rm * /rw/CT8016/support/outsupport.tar");
        system(command);
        
    } 
    
} 

/**/
- (void) checkForSupportTask
{
	COLLECTION files;
	char *fileName;
	int i;
    char command[512];
    int result;

    printf("chequea si hay nuevas tareas\n");

	files = [File findFilesByExt: SUPPORT_PATH 
		extension: "tar" 
		caseSensitive: FALSE 
		startsWith: SUPPORT_TASK_START_WITH_NAME];

    printf("cantidad de archivos encontrados = %d\n", [files size]);
	for (i = 0; i < [files size]; ++i) {

		fileName = (char *)[files at: i];

		sprintf(myCompleteFileName, "%s/%s", SUPPORT_PATH, fileName);

        printf("myCompleteFileName =%s\n", myCompleteFileName);
		[self startTask: fileName];
        [self stopTask];

        if (myCanDeleteTask) {
			unlink(myCompleteFileName);
            
            printf("Borrando carpeta unzip");
            sprintf(command, "rm * %s/unzip", SUPPORT_PATH);
	        result = system(command);
        	printf("Comando ejecutado %s, resultado = %d\n", command, result);

            
		}
	}

	[files freePointers];
	[files free];
    
    
    //chequea que haya un resultado para supervisarlo a la pims
    [self checkResult];

    
}


/**/
- (void) run 
{

	printf("Iniciando hilo de soporte...\n");

    
    /***************   PENDIENTE BORRAR TODOS LOS ARCHIVOS POR SI QUEDO ALGO ****************************/
  TRY

  
  
	while (TRUE) {

		msleep(SUPPORT_CHECK_TIME);
       /*
        if (![[CimManager getInstance] isSystemIdle]) {
            printf("El sistema no esta Idle\n");	
            continue;
        }
        */
		// chequea si hay alguna tarea de soporte
		[self checkForSupportTask];

	
	}

	CATCH

    
//			doLog(0,"Excepcion en el hilo de actualizacion de firmware...\n");
			ex_printfmt();

	END_TRY


}



@end
