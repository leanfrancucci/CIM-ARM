#include "ImasConfigLauncher.h"
#include "ImasConfiguration.h"
#include "FileManager.h"
#include "UpdateImasConfiguration.h"
#include "RetransImasConfiguration.h"
#include "StateImasConfiguration.h"
#include "GeneralImasConfiguration.h"
#include "TelesupervisionManager.h"

#define printd(args...) //doLog(0,args)

@implementation ImasConfigLauncher

/**/
+ new
{
	return [[super new] initialize];	
}

/**/
- initialize
{	
	files 	=[Collection new];
	/*reseteo el indice de archivos procesados*/
	fIndex=0;
	return self;
}

/**/
-(int) launchConfiguration:(char *)filename telesupD:(TI_TELESUPD)tD
{
	char ext[5];
	int result = 0;
	char *dest = (char *) malloc(500);
	IMAS_CONFIGURATION imasConf = NULL;
	
  *dest = 0;

	printd("Filename %s -\n",filename);
	
	[[FileManager getDefaultInstance] extractFileExtension: filename extension:ext];
	printd("Extension %s -\n",ext);
	
	/*dependiendo de la extension creo una u otra configuracion*/
		
	if (strncasecmp(ext,"tec",3)== 0) {
	/******************* tabla de tarfas **********************/
		printd("Configuracion de tabla de tarifas\n");
/*		imasConf= [TariffImasConfiguration new];
		strcpy(dest,[[Configuration getDefaultInstance] getParamAsString: "IMAS_TABLE_PATH"]);*/
	} else if (strncasecmp(ext,"gz",2)== 0 || strncasecmp(ext,"tgz",3)== 0){ 
  /******************* update.tar.gz ************************/
		printd("Configuracion de Actualizacion de Modulos\n");		
		imasConf= [UpdateImasConfiguration new];
		strcpy(dest,[[Configuration getDefaultInstance] getParamAsString: "IMAS_UPDATE_PATH"]);
	} else if (strncasecmp(ext,"ret",3)== 0) {
	/******************** Retransmiciones *********************/
		printd("Configuracion de retransmisiones\n");		
		imasConf= [RetransImasConfiguration new];
		[imasConf setTelesupDaemon:tD];
	}

  if (imasConf) {
  	[imasConf setTelesupId: [tD getTelesupRol]];
  	if ([imasConf applyConfiguration:filename destination:dest]) result= 1;
    [imasConf free];
	}

	free(dest);
	
	/*no existe la extension que posee el archivo pasado por parametros*/
	return result;
}

/**/
-(char *) nextFile:(char *) buffer
{
	if (fIndex < [files size]){
		strcpy(buffer,(char*) [files at: fIndex]);
		++fIndex;
		return buffer;
	}
	return NULL;
	
}

/**/
 - (COLLECTION) getFilesCollection
 {
 	return files;	
 }
 

/**/
- free
{
	char *path;
	int i;
	
	// Elimino la lista
	for (i = 0; i < [files size]; ++i) {
		path = (char*)[files at: i];
		free(path);
	}
	[files free];
	return [super free];
}

/**/
+ (void) applyGeneralConfiguration
{
  id imasConf;
	char *filename= (char *) malloc(100);
	char *completePath= (char *) malloc(500);
  char ext[10];
  char *dest = malloc(100);
  IMAS_CONFIG_LAUNCHER imasConfigLauncher;
  int result = 0;
  TELESUP_SETTINGS telesup;
  int telesupId;

  *dest = 0;
  telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: IMAS_TSUP_ID];
  if (!telesup) return;

  telesupId = [telesup getTelesupId];

  imasConfigLauncher = [ImasConfigLauncher new];

	[[FileManager getDefaultInstance] loadDirectory:[[FileManager getDefaultInstance] getDataDestinationDir] list: [imasConfigLauncher getFilesCollection]];

	while ([imasConfigLauncher nextFile:filename]!= NULL) {

  	[[FileManager getDefaultInstance] extractFileExtension: filename extension:ext];

    imasConf = NULL;

    if (strcasecmp(ext, "cfc") == 0) {

      printd("Configuracion general\n");
      imasConf= [GeneralImasConfiguration new];
      sprintf(completePath,"%s/%s",[[FileManager getDefaultInstance] getDataDestinationDir],filename);
		  printd("%s---\n",completePath);

    } else if (strcasecmp(ext, "est") == 0) {

      printd("Configuracion de Estado\n");
			imasConf= [StateImasConfiguration new];
      sprintf(completePath,"%s/%s",[[FileManager getDefaultInstance] getDataDestinationDir],filename);
		  printd("%s---\n",completePath);

    }
    
    if (imasConf) {
      [imasConf setTelesupId: telesupId];
      if ([imasConf applyConfiguration:completePath destination:dest])
	     result= 1;
      [imasConf free];
    }

	}

  [imasConfigLauncher free];
  free(filename);
  free(completePath);
  free(dest);

}

@end
