#include "RetransImasConfiguration.h"
#include "system/util/all.h"
#define printd(args...) //doLog(0,args)

@implementation RetransImasConfiguration

-(void) setTelesupDaemon:(TI_TELESUPD)t
{
	tD =t;
	printd("SetDaemon\n");
}
/**/
-(int) applyConfiguration:(char *) filename destination:(char*) dest
{
	FILE *f;
	int i=0;
	char ch;
	char line[25];
	char tipo[4];
	char fechaDesde[10];
	char fechaHasta[10];
	datetime_t sDate;
	datetime_t eDate;
	int year, month,day;
	char fn[100];
	char fn2[100];
  struct tm bt;
  CIPHER_MANAGER cipherManager;
  char tmpFileName[255];
  int fSize;

	strcpy(fn,"r0000000000000");

	[[FileManager getDefaultInstance] extractFileName:filename filename:fn2];
	strrep(fn2, '.',0);
	strcpy(&fn[14- strlen(fn2)],fn2);

 	printd("applyConfiguration: %s - %s\n",filename, dest);

  fSize = [[FileManager getDefaultInstance] getFilesize: filename];
  cipherManager = [CipherManager new];
  sprintf(tmpFileName, "%sdec", filename);
  [cipherManager decodeFile: filename destination: tmpFileName size: fSize];
  [cipherManager free];

  [[FileManager getDefaultInstance] deleteFile:filename];
	
	printd("File_Name sin extencion ni path completo: %s\n",fn);

	f=fopen(tmpFileName,"rb");
	if (f==NULL)
		return 0;
	
	while (1){
		i=0;
		while (((ch = getc(f)) != EOF) && (ch != 10)){
			line[i]=ch;			
			++i;
		}
		if (!(ch == 10))/*finalizo una linea*/
			if (i==0) { /*no hay mas lineas*/
				fclose(f);
        // Borro el archivo de retransmicion
        [[FileManager getDefaultInstance] deleteFile:tmpFileName];
        return 0;
      }

		line[i]=0;
		printd("%s \n",line);
		strncpy(tipo,&line[1],3);
		tipo[3]=0;
		strncpy(fechaDesde,&line[4],8);
		fechaDesde[8]=0;
		strncpy(fechaHasta,&line[12],8);				
		fechaHasta[8]=0;
	//	printd("Tipo Retransmicion: %s \nFecha Desde: %s \nFechaHasta: %s \n",tipo, fechaDesde,fechaHasta);
		
		day   	= (fechaDesde[0]-48)*10 + (fechaDesde[1]-48);
		month 	= (fechaDesde[2]-48)*10 + (fechaDesde[3]-48);
		year	= (fechaDesde[4]-48)*1000 + (fechaDesde[5]-48)*100+ (fechaDesde[6]-48)*10+ (fechaDesde[7]-48);
		sDate	= [SystemTime encodeTime: year mon: month day: day hour: 0 min: 0 sec: 0];
		
		day   	= (fechaHasta[0]-48)*10 + (fechaHasta[1]-48);
		month 	= (fechaHasta[2]-48)*10 + (fechaHasta[3]-48);
		year	= (fechaHasta[4]-48)*1000 + (fechaHasta[5]-48)*100+ (fechaHasta[6]-48)*10+ (fechaHasta[7]-48);
		eDate	= [SystemTime encodeTime: year mon: month day: day hour: 23 min: 59 sec: 59];
    
    sDate = [SystemTime convertToLocalTime: sDate];
    eDate = [SystemTime convertToLocalTime: eDate];
		
    gmtime_r(&sDate, &bt);
  //  doLog(0,"--- > start : %04d-%02d-%02d %02d:%02d\n", bt.tm_year+1900, bt.tm_mon+1, bt.tm_mday, bt.tm_hour, bt.tm_min);

    gmtime_r(&eDate, &bt);
   // doLog(0,"--- > end   : %04d-%02d-%02d %02d:%02d\n", bt.tm_year+1900, bt.tm_mon+1, bt.tm_mday, bt.tm_hour, bt.tm_min);
  
		printd("Llamada Fecha desde :%ld Fecha Hasta: %ld\n",sDate,eDate);		

		if (strcmp(tipo,"auc")==0 ){
			printd("Regenerando Auditoria\n");
			[tD genFile: "GET_AUDITS_IMAS" fileName:"audits.auc" fixedFilename:fn fromDate:sDate toDate:eDate activefilter:1];
			printd("Regeneracion de auditoria OK\n");
			/*borro el archivo*/
		  //[[FileManager getDefaultInstance] deleteFile:filename];
		}
	}
		
}

@end
