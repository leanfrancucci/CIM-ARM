#include "FileManager.h"
#include "MessagesImas.h"
#include <sys/stat.h>
#include "system/db/all.h"
#include "system/util/all.h"
#include <dirent.h>

#define IMAS_MAX_FILE_SIZE	500000
#define MAX_FILE_PART_QTY	999

static FILE_MANAGER singleInstance = NULL;
#define printd(args...) //doLog(0,args)
@implementation FileManager

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{	
	cipherManager 	= [CipherManager new];
	bufferRxFile	= (unsigned char *) malloc(BUFFER_RX_SIZE);
	
	/* directorio destino donde se almacenaran los archivos recibidos en la telesupervision*/
	strcpy(destinationDir,[[Configuration getDefaultInstance] getParamAsString: "IMAS_DOWNLOAD_PATH"]);
	printd("DestinationDir: %s\n",destinationDir);
	
	/* directorio donde los proceso de generacion y regeneracion de archivos a enviar*/
	strcpy(sourceDir,[[Configuration getDefaultInstance] getParamAsString: "IMAS_FILES_TO_SEND_PATH"]);
	printd("SourceDir: %s\n",sourceDir);	
	return self;
}

/**/
- (void) setSourceDir: (char *) aSourceDir
{
	if (aSourceDir == NULL) 
		strcpy(sourceDir, [[Configuration getDefaultInstance] getParamAsString: "IMAS_FILES_TO_SEND_PATH"]);
	else 
		strcpy(sourceDir, aSourceDir);
}

/**/
+ getDefaultInstance
{
	if (singleInstance) 
		return singleInstance;
	
	singleInstance = [self new];
	return singleInstance;
}

- (void) setTelesupViewer: (id) aViewer
{
  telesupViewer = aViewer;

}

/**/
-(int) loadDirectory: (char *) directory list:(COLLECTION) files
{
	int i;
	char *fileName=(char *) malloc(200);
	char *completePath=(char *) malloc(500);
	struct dirent *dp;
	DIR *dfd;
	char *name;
	char *index;	
	
	/* Recorro el directorio buscando los archivos*/
	dfd = opendir(directory);
	
	while ( (dp = readdir(dfd)) != NULL ){
		index = strrchr(dp->d_name, '.');
		if (index == NULL) 
			continue;
		++index;
		
		if (strcmp(index,"")==0) 
			continue;
		name = strdup(dp->d_name);
		[files add: name];
	}

	closedir(dfd);
	
	/*no hay archivos en el directorio*/
	printd("Load DIrectory: %s\n",directory);
	if ([files size] == 0){
		printd("No hay archivos\n");
		return 0;
	}
	
	/*listo los archivos detectados*/
	for (i = 0; i < [files size]; ++i){
		fileName = (char*) [files at: i];
		sprintf(completePath, "%s/%s", directory, fileName);
		printd("%s\n",completePath);
	}
	
	return [files size];
}
/**/
-(short) getFileChecksum:(char * )filename
{
	FILE *fo;
	short chk=0;
	long fSize,i;
	char buffer[2];

	fSize=[self getFilesize:filename];

	fo = fopen(filename, "r+b");
	if (fo == NULL)
		return 0;
		
	for(i=0;i<fSize;++i){
		fread(buffer,1,1,fo);		
		chk+= buffer[0];
	}

	fclose(fo);
	return chk;
}

/**/
-(int) initSendFilesToSend:(char *) idEq
{
	files 			= [Collection new];
	[self loadDirectory:sourceDir list: files];
	fIndex=0;
	return 1;
}

/**/
- (void) deinitSendFilesToSend
{
	char *path;
	int i;
	
	// Elimino la lista
	for (i = 0; i < [files size]; ++i) {
		path = (char*)[files at: i];
		free(path);
	}
	[files free];
}

/**/
/*-(int) getNextFileToSend:(char * )filename
{
	if (fIndex < [files size]){
		strcpy(filename,(char*) [files at: fIndex]);
		++fIndex;
		return 1;
	}
	return 0;
}*/
-(int) getNextFileToSend:(char * )filename
{
  char ext[4];

  if (fIndex < [files size]) {
    while (fIndex < [files size]){
      strcpy(filename,(char*) [files at: fIndex]);  
      [self extractFileExtension: filename extension:ext];
      ++fIndex;
      if ((strcmp(ext,"auc") == 0) || (strcmp(ext,"trc") == 0)) return 1;
      else //si es otra cosa lo elimino
        [self deleteFile:filename];
    }
  }

  return 0;
}


/**/
-(long) getFilesize:(char *)FileName
{     
    struct stat file;
     
     if(!stat(FileName,&file))
         return file.st_size;
 
     return 0;
}

/**/
-(int) deleteFile:(char *)FileName
{     
   return remove(FileName);
}

/**/
- renameFiles:(int)qty fName:(char *)fName
{
	int i;
	char *nfn = (char *) malloc(250);
	char *ofn = (char *) malloc(250);
	char *fn  = (char *) malloc(250);
	char ext[5];
	
//	doLog(0,"fname = %s\n", fName);
	
	strncpy(fn,fName,strlen(fName)-4);//nombre de archivo sin extension
	fn[strlen(fName)-4] = 0;

	strncpy(ext,&fName[strlen(fName)-3],3);//obtengo la extension	
	ext[3]=0;

	for (i=1;i <= qty;++i){
		sprintf(nfn,"%s_%03d_%03d.%s",fn,i,qty,ext);
		printd("NFN: %s\n",nfn);
		sprintf(ofn,"%s_%03d_TEMP.%s",fn,i,ext);
		printd("OFN: %s\n",ofn);
		rename(ofn,nfn);
	}
	
	free(nfn);
	free(ofn);
	free(fn);
}
/**/
- (void) splitFile:(char *) fileName splitSize: (long) sSize
{
	FILE *fi;
	FILE *fo;
	long fSize=[self getFilesize:fileName];
	int fQty=0;
	char *sFn= (char *) malloc(250);
	char *fn = (char *) malloc(250);	
	char ext[5];
	char buf[5];
	long bReaded=0;
	long bAcum=0;
		
	if (sSize != 0){
		/* si se superan las 999 fraciones de un archivo debo modificar el tama�o de cada parte*/
		sSize= sSize * 1024;/*el tama�o de cada parte biene expresado en kb y lop necesito en bytes*/
		printd("FileSize: %ld Longitud partes :%ld\n",sSize,fSize);
		if (( fSize / sSize ) > MAX_FILE_PART_QTY)
			sSize = fSize / (MAX_FILE_PART_QTY - 1);
		
		fi= fopen(fileName,"rb");
		
		if (fi== NULL)
			return;
		memset(fn,0,250);
		strncpy(fn,fileName,strlen(fileName)-4);//nombre de archivo sin extension
		strncpy(ext,&fileName[strlen(fileName)-3],3);//obtengo la extension
		ext[3]=0;
		printd("FileName: %s - %s - %s\n",fileName,fn,ext);
	
//		while ((fSize>0) && (bReaded <= fSize)){
		while ((fSize>0) && (bReaded < fSize)){
			++fQty;
			sprintf(sFn,"%s_%03d_TEMP.%s",fn,fQty,ext);
			printd("Split: %02d - %s\n",fQty,sFn);
			fo=fopen(sFn,"wb");
			
			/*leo hasta el fin de archivo o hasta la cantidad maxima por parte*/
//			while ((bReaded <= fSize)&& (bAcum <= sSize)){
			while ((bReaded < fSize)&& (bAcum < sSize)){
				fread(&buf,1,1,fi);
				fwrite(&buf,1,1,fo);
				++bReaded;
				++bAcum;
			}
			
			/*si no llego al fin de archivo leo hasta el enter*/
//			if (bReaded <= fSize){
			if (bReaded < fSize){
//				while ((bReaded <= fSize) && (buf[0] != 0x0A)){
				while ((bReaded < fSize) && (buf[0] != 0x0A)){
					fread(&buf,1,1,fi);
					fwrite(&buf,1,1,fo);
					++bReaded;
				}
			}
			
			fclose(fo);
			bAcum=0;
		
		}
		printd("Cierro el archivo\n");
		fclose(fi);
		
		/*si no tiene bytes el archivo armo el archivo 001_001*/	
		if (fSize == 0){
			sprintf(sFn,"%s_001_001.%s",fn,ext);
			printd("Split: %02d - %s\n",++fQty,sFn);	
			rename(fileName,sFn);	
		}		
			
		/*coloco a cada archivo la cantidad total de archivos que lo componen*/
		[self renameFiles:fQty fName:fileName];
		
		[self deleteFile:fileName];
	}
	else{
		/*el tama�o de parte es cero, por lo tanto no tengo que particionar el archivo*/
		sprintf(sFn,"%s_001_001.%s",fn,ext);
		printd("Split Unico: %s\n",sFn);	
		rename(fileName,sFn);
	}
	
	free(sFn);
	free(fn);
		
}

/**/
-(int) validateDate:(char)filtered startDate:(datetime_t)sDate endDate:(datetime_t)eDate aDate:(datetime_t)aDate
{
	if (!filtered)
		return 1;
	
	/*valido si la fecha del ticket entra en el rango*/
	//printd("Fecha desde :%ld Fecha Hasta: %ld Fecha: %ld\n",sDate,eDate,aDate);
	return  ((sDate <= aDate) && (aDate <= eDate));

}

/**/
- (void) prepareFile: (char *) fName fixedFileName:(char *)fFname
{
	struct tm brokentime;
	char *fn = (char *) malloc(150);
	char *nfn= (char *) malloc(150);
	char *ofn= (char *) malloc(150);
	char ext[5];
	

	/*obtengo la extencion del archivo*/	
	[self extractFileExtension: fName extension:ext];
	
	if (strcmp(fFname,"")==0){
		/*renombro los archivos con la fecha y hora actual*/
		[SystemTime decodeTime: [SystemTime getLocalTime] brokenTime:&brokentime];
		
		snprintf(fn, 20, "%02d%02d%4d%02d%02d%02d",
					brokentime.tm_mday,			// dia 
					brokentime.tm_mon  + 1,		// mes 
					brokentime.tm_year + 1900,	// a?o 				
					brokentime.tm_hour,			// hora
					brokentime.tm_min,			// minutos 
					brokentime.tm_sec			// segundos 	
		);
	}
	else
		/*tiene un nombre fijo*/
		strcpy(fn,fFname);
		
	sprintf(nfn,"%s/%s.%s",sourceDir,fn,ext);
	sprintf(ofn,"%s/%s",sourceDir,fName);
	rename(ofn,nfn);
	printd("Termino %s a %s\n",ofn,nfn);
	
	/*particiono el archivo*/
	[self splitFile:nfn splitSize: 500];
	
	free(fn);
	free(nfn);
	free(ofn);

}

/**/
-(int) validateFile: (char *) filename
{
	FILE *fo;
	short chk=0,chkAlm=0,stmp;
	unsigned char tmp,tmp2;
	long fSize;
	
	chk= [self getFileChecksum:filename];

	fSize=[self getFilesize:filename];
	
	fo = fopen(filename, "r+b");		
	fseek(fo,fSize-2,SEEK_SET);
	
	/*como la funcion de calculo de checsum del achivo suma todos los bytes del mismo, entonces resto el valos de los ultimo dos bytes del archivo*/
	fread(&tmp,1,1,fo);
	chk-=(char) tmp;
	fread(&tmp2,1,1,fo);
	chk-=(char)tmp2;
	
	stmp= (short) tmp2;
	stmp= stmp << 8;
	chkAlm = tmp + stmp;
	fclose(fo);
	printd("  #Chk calc %d Chk Alm %d \n",chk,chkAlm);

	return chk == chkAlm;
}

/**/
-(int) receiveFile:(char *) filename fSize:(unsigned long) fileSize proxy:(TI_REMOTE_PROXY) rProxy
{
	unsigned long bytesRx;
	unsigned long bytesToRead;	
	unsigned char byteRec;
	char archivoTmp[200];
  char archivo[200];
	FILE *fo;

	printd("\n  * * * * * RECIBO ARCHIVO * * * * * \n\n");
	
	[rProxy newMessage: MSG_OK_ENTER];
	[rProxy sendMessage];
		
	/*recibo todos los bytes del archivo*/
	bytesRx=0;
	sprintf(archivoTmp,"%s/%stmp",destinationDir,[rProxy getParameterNumber:1]);
	
	printd("  #Recibiendo Archivo %s %s bytes. Espere por favor.\n",archivoTmp,[rProxy getParameterNumber:2]);
	
	printd("    - Generando Archivo Temporal...(%s)\n",archivoTmp);
	fo = fopen(archivoTmp,"w+b");
	if (fo == NULL){
		printd("  ERROR: al Generar Archivo Temporal!!!\n");
		return 0;
	}			
	else
		printd("    - Archivo Temporal Generado!\n");
		
	while (bytesRx < fileSize){			
		if ([rProxy receiveMessage:1]){
			byteRec= [rProxy getMsgReceived][0];
			if (fwrite(&byteRec,1,1,fo))
				++bytesRx;
			else{
				printd("  ERROR: Intentando Abrir el Archivo Temporal\n");
				fclose(fo);
				return 0;
			}
		}
		else{
			printd("  ERROR: Timeout\n");
			fclose(fo);
			return 0;
		}
	}
	fclose(fo);
	printd("  #Archivo Recibido %ld bytes\n",bytesRx);

	/* espero el endSendFile*/
	bytesToRead=strlen(MSG_ENDSENDFILE);
	bytesRx=[rProxy receiveMessage:bytesToRead];
	if (bytesRx == bytesToRead){						

		if (strcmp([rProxy getMsgReceived],MSG_ENDSENDFILE)== 0){

			sprintf(archivo,"%s/%s",destinationDir,[rProxy getParameterNumber:1]);
			strcpy(archivoTmp, archivo);
			strcat(archivoTmp,"tmp");

			printd("  #Verificando integridad del archivo...\n");

			/*verifico integridad del archivo*/
			if ([self validateFile:archivoTmp]){
				printd("  #Archivo V�lido\n");

//				[cipherManager decodeFile:archivoTmp destination:[rProxy getParameterNumber:1] size:[self getFilesize:archivoTmp]];					
				/*elimino el temporal codificado*/
//				[self deleteFile:archivoTmp];
//				printd("  #Archivo Temporal Eliminado\n");
        unlink(archivo);
        rename(archivoTmp,archivo);
				[rProxy newMessage: MSG_OK_ENTER];
				[rProxy sendMessage];
				printd("  #Confirmacion enviada \n\n");
				return 1;
			}
			else{
				[self deleteFile:archivoTmp];
				printd("  ERROR: Checksum del Archivo Invalido\n");
				[rProxy newMessage: MSG_MAL];
				[rProxy sendMessage];
				printd("  #Anulacion enviada \n");
			}
		}
		else
			printd("  ERROR: No llego el endSendFile!!!!\n");
	}
	else
		printd("  ERROR: Recibio %ld bytes y esperaba %ld bytes!!!!\n",bytesRx,(unsigned long) strlen(MSG_ENDSENDFILE_ENTER));

	return 0;
}

/**/
-(int) sendFile:(char *)filename proxy:(TI_REMOTE_PROXY) rProxy
{
	FILE *fo;
	int bytesTx,fSize,bl,retries=0;
	char st[500],fn[100];
	short chk;
	unsigned char chktmp;
  long fileSize = 0;

retry:
	/*seteo el checksum al archivo*/
	sprintf(fn,"%s/%s",sourceDir,filename);	
	strcpy(st,fn);
	strcat(st,".tmp");
  
  // Copio a un archivo 
  [self copyFile: fn To: st];

  fileSize = [self getFilesize:fn];

	printd("Filesize original = %d\n", fileSize);

//	[cipherManager encodeFile:fn destination:st size:fileSize];

	[telesupViewer startFileTransfer: fn download: FALSE totalBytes: fileSize+2];

	chk=[self getFileChecksum:st];
	fo = fopen(st, "a+b");
	chktmp=chk & 255;
	fwrite(&chktmp,1,1,fo);
	chktmp=(chk >> 8) & 255;
	fwrite(&chktmp,1,1,fo);
	fclose(fo);

	fSize=[self getFilesize:st];
	sprintf(st,"%s,%s,%ld,NOZIP\xD\xA",MSG_SENDFILE,filename,fSize);
	printd("%s\n",st);
	/*envio el header del archivo*/
	printd("  #Enviar Archivo: %s Tama�o: %ld bytes\n",fn,fSize);
	if ([rProxy sendAndVerifyPkt:st size:2 qty:1]){
		if (strncmp([rProxy getParameterNumber:0],MSG_OK,2)==0){		
			strcpy(st,fn);
			strcat(st,".tmp");
			fo = fopen(st,"r+b");
			bytesTx=0;
			printd("  #Inicio de Envio de bytes...\n");
			while (bytesTx < fSize){
				memset(bufferRxFile,0,BUFFER_RX_SIZE);
				bl= fread(bufferRxFile,1500,1,fo);
				if (bl == 1)
					bl=1500;
				else
					bl= fSize -bytesTx;
									
				if (![rProxy sendBuffer: bufferRxFile qty: bl]){				
					printd("  ERROR: Transfiriendo el archivo\n");
					return 0;
				}
				else {
					printd("  Transferido: %ld de %ld bytes (%6.2f).\n",bytesTx ,fSize, ((bytesTx*100.0)/fSize)+1);					
					[telesupViewer updateFileTransfer: bytesTx];
				}

				bytesTx = bytesTx + bl;
			}
			printd("  #Fin de Envio de bytes...\n");
			fclose(fo);
      [self deleteFile:st];

			[telesupViewer updateFileTransfer: fSize];

			/* espero el ok del server*/
			if ([rProxy receiveMessage:2]){
				if (strncmp([rProxy getMsgReceived],MSG_OK,2)==0){				
					printd("  #Archivo transferido con exito!!!\n");
					if ([[Configuration getDefaultInstance] getParamAsInteger: "IMAS_DELETE_AFTER_SEND" default: 1])
            [self deleteFile:fn];

					strcat(fn,".enc");
					[self deleteFile:fn];
					printd("  #Archivo Temporal Eliminado\n");
				}
				else{
					if (strncmp([rProxy getParameterNumber:0],MSG_MAL,3)== 0){					
						if (retries == 3){
							printd("  ERROR: Maxima Cantidad de Reenvios superada. Se saltea el archivo.\n");
							return 0;
						}	
						printd("  ERROR: Archivo incorrecto se reenvia el archivo %s\n",fn);
						++retries;
						goto retry;
					}
					else{
						printd("  ERROR: Esperando Rta al EndSendFile\n");
						return 0;
					}
				}
			}
			else{
				printd("  ERROR: Esperando OK del archivo enviado...\n");
				return 0;
			}
		}
		else{
			printd("  ERROR: Esperando OK sendFile\n");
			return 0;
		}			
	}	
	else{
		printd("  ERROR: Esperando OK sendFile\n");
		return 0;
	}

	return 1;
	
}

/**/
-(char *) getDataSourceDir
{
	return sourceDir;
}

/**/
-(char *) getDataDestinationDir
{
	return destinationDir;
}

/**/
-(int) copyFile:(char *) source To:(char *) destination
{
	FILE *fi;
	FILE *fo;
	long fSize,i;
	char buffer[2];
	
	printd("Origen: %s Destino %s\n",source,destination);
	fi=fopen(source,"rb");
	if (fi == NULL)
		return 0;
		
	fo=fopen(destination,"w+b");
	if (fo == NULL)
		return 0;
		
	fSize=[self getFilesize:source];
	printd("copyFile -> bytes a copiar = %d\n", fSize);
	
	for(i=0;i<fSize;++i){
		fread(buffer,1,1,fi);
		fwrite(buffer,1,1,fo);
	}
	
	fclose(fo);
	fclose(fi);
	
	return 1;
}

/**/
-(char *) extractFileName: (char *)path filename:(char *) fn
{
	int i=strlen(path)-1;
	
	while (i>=0){
		if (path[i]== '/')
			break;
		--i;
	}
	++i;
	strcpy(fn,&path[i]);
	
	return fn;
}

/**/
-(char *) extractFileExtension: (char *)path extension:(char *) ext
{
	int i=strlen(path)-1;
	
	while (i>=0){
		if (path[i]== '.')
			break;
		--i;
	}
	++i;
	strcpy(ext,&path[i]);
	
	return ext;
}


/**/
- free
{
	[cipherManager free];
	free(bufferRxFile);
	return [super free];
}
@end
