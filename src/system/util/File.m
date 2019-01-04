#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <strings.h>
#include "File.h"
#include "UtilExcepts.h"

//#define printd(args...) doLog(args)
#define printd(args...)

char *strdup(const char*);
 
@implementation File

/**/
+ (COLLECTION) findFilesByExt: (char*) aPath extension: (char*) anExtension
							 caseSensitive: (BOOL) aCaseSensitive startsWith: (char *) aStartsWith
{
	struct dirent *dp;
	DIR *dfd;
	COLLECTION files = [Collection new];
	char *name;
	char *index;

	printf("Try to opendir |%s|\n", aPath);
	
	dfd = opendir(aPath);
	if (!dfd) THROW_MSG(INVALID_PATH_EX, aPath);

	// Recorro el directorio buscando tablas de tarifas
	
	while ( (dp = readdir(dfd)) != NULL )
	{

		printf("File -> Analizando archivo %s, type = %d\n", dp->d_name, dp->d_type);
		
		//if (dp->d_type != 8) continue;
		printf("File -> Es un archivo\n");
		
		index = strrchr(dp->d_name, '.');
		if (index == NULL && strlen(anExtension) != 0) continue;
		printf("File -> Contiene una extension\n");
		if (index) index++;
		
        
        printf("index =%s extension = %s", index, anExtension);
        
		// No coincide con el criterio, continuo hacia el siguiente
		if (aCaseSensitive) {
			if (index != NULL && strcmp(index, anExtension) != 0) continue;
		} else {
			if (index != NULL && strcasecmp(index, anExtension) != 0) continue;
		}

		// Si el archivo debe comenzar con cierta cadena, verifica eso
		if (strlen(aStartsWith) != 0) {
			index = dp->d_name;
			printf("Comienza |%s| con |%s|?\n", index, aStartsWith);
			if (strstr(index, aStartsWith) != index) continue;
		}

		printf("File -> OK. Lo agrego a la lista\n");

		name = strdup(dp->d_name);
		[files add: name];
		

	} // while

	closedir(dfd);
	
	return files;
	
}

/**/
+ (COLLECTION) findFilesByExt: (char*) aPath extension: (char*) anExtension
							 caseSensitive: (BOOL) aCaseSensitive
{
	struct dirent *dp;
	DIR *dfd;
	COLLECTION files = [Collection new];
	char *name;
	char *index;

	printd("Try to opendir |%s|\n", aPath);
	
	dfd = opendir(aPath);
	if (!dfd) THROW_MSG(INVALID_PATH_EX, aPath);

	// Recorro el directorio buscando tablas de tarifas
	
	while ( (dp = readdir(dfd)) != NULL )
	{

		printd("File -> Analizando archivo %s, type = %d\n", dp->d_name, dp->d_type);
		
		//if (dp->d_type != 8) continue;
		printd("File -> Es un archivo\n");
		
		index = strrchr(dp->d_name, '.');
		if (index == NULL && strlen(anExtension) != 0) continue;
		printd("File -> Contiene una extension\n");
		if (index) index++;
		
		// No coincide con el criterio, continuo hacia el siguiente
		if (aCaseSensitive) {
			if (index != NULL && strcmp(index, anExtension) != 0) continue;
		} else {
			if (index != NULL && strcasecmp(index, anExtension) != 0) continue;
		}
		printd("File -> OK. Lo agrego a la lista\n");

		name = strdup(dp->d_name);
		[files add: name];
		

	} // while

	closedir(dfd);
	
	return files;
	
}

/**/
+ (char*) extractFileName: (char *) aPath
{
	if (strchr(aPath, '\\') == NULL) return aPath;
	return strrchr(aPath, '\\') + 1;
}

/**/
+ (BOOL) existsFile: (char*) aPath
{
	FILE *f = fopen(aPath, "r");
	if (!f) return FALSE;
	fclose(f);
	return TRUE;
}

/**/
+ (BOOL) makeDir: (char*) aPath
{
	return makeDir(aPath) == 0;
}

/**/
+ (long) getFileSize: (char*) aPath
{
	long size;	
	FILE *f = fopen(aPath, "rb");

	if (!f) THROW_MSG(FILE_NOT_FOUND_EX, aPath);
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	
	fclose(f);
	return size;
}

@end
