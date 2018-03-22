#include "system/util/all.h"
#include "TIInfoFormatter.h"
#include "SystemTime.h"
#include "InfoFormatter.h"
#include "TelesupDefs.h"
#include "TelesupFacade.h"
#include "UserManager.h"
#include <math.h>

//#define printd(args...) doLog(args)
#define printd(args...)// doLog(0,args)

static char * convertDateTime(char *buf, datetime_t aValue)
{
	struct tm brokentime;

	gmtime_r(&aValue, &brokentime);
	
	snprintf(buf, 35, "%02d/%02d/%04d %02d:%02d:%02d",
				brokentime.tm_mday,			// dia 
				brokentime.tm_mon  + 1,		// mes 
				brokentime.tm_year + 1900,	// a?o 				
				brokentime.tm_hour,			// hora
				brokentime.tm_min,			// minutos 
				brokentime.tm_sec			// segundos 	
	);
	
	return buf;
}

char * strToImasFormat(char *buf)
{
	char b[200];
	
	strcpy(b,buf);
	
	if (strcmp(b,"") == 0)
		strcpy(buf,"null");
	else 
		sprintf(buf,"'%s'",b);
	
	return buf;
}

@implementation TIInfoFormatter

/**/
- initialize
{
	[super initialize];
	myUsersRS = [[DBConnection getInstance] createRecordSet: "users"];	
	[myUsersRS open];
	return self;
}

/**/
- free
{
	[myUsersRS close];
	[myUsersRS free];
	return [super free];
}

/**/ 
- (int) writeLong: (long) aValue
{	
	char lValue[15];
	
	sprintf(lValue,"%ld",aValue);
	strcpy(myBuffer,lValue);
	myBuffer += strlen(lValue);
	return strlen(lValue);
}	

/**/
- (int) writeDateTime: (datetime_t) aValue
{
	struct tm brokentime;
	char buf[500];
	char *i;

	gmtime_r(&aValue, &brokentime);
	
	snprintf(buf, 35, "'%02d/%02d/%04d %02d:%02d:%02d'",
				brokentime.tm_mday,			// dia 
				brokentime.tm_mon  + 1,		// mes 
				brokentime.tm_year + 1900,	// a?o 				
				brokentime.tm_hour,			// hora
				brokentime.tm_min,			// minutos 
				brokentime.tm_sec			// segundos 	
	);
	
	for(i=buf;i< (buf+strlen(buf));++i)
		[self writeChar: *i];		
	
 	return strlen(buf);
}

/**/
- (int) writeMoney: (money_t) aValue
{
	char amount[20];
	
	formatMoney(amount,"",aValue,6,15);
	
	return [self writeString: amount qty:strlen(amount)];
}

/**/
- (int) writeShort: (short) aValue
{
	char sValue[15];
	
	sprintf(sValue,"%d",aValue);
	strcpy(myBuffer,sValue);
	myBuffer += strlen(sValue);
	return strlen(sValue);		
}

/**/
- (int) writeText: (char *) aText
{
	return [self writeString: aText qty: strlen(aText)];
}

/**/ 
- (int) getAuditSize
{
	return 24;
}

/**/
- (int) formatAudit: (char *) aBuffer audits: (ABSTRACT_RECORDSET) auditsRS
{
	char *idSoft;
	char userName[100];
	TELESUP_FACADE facade = [TelesupFacade getInstance];
  char station[100];

	assert(auditsRS);
	assert(aBuffer);
	
	[self setBuffer: aBuffer];

	/*obtengo el usuario*/
	[myUsersRS moveBeforeFirst];		
	strcpy(userName,"");
	if ([myUsersRS findById:"USER_ID" value:[auditsRS getShortValue:"USER_ID"]])
		[myUsersRS getStringValue: "LOGIN_NAME" buffer:userName];			
	
	/*obtengo el idsoftware de los parametros de telesup*/
	idSoft 		= [facade getTelesupParamAsString: "SystemId" telesupRol: myTelesupId];

	[self writeString: "P_INS_AUDITORIA_CT8016(" qty: strlen("P_INS_AUDITORIA_CT8016(")];
	[self writeString: idSoft qty:strlen(idSoft)];
	[self writeChar: ','];
	[self writeShort: 		[auditsRS getShortValue: 	"EVENT_ID"]];
	[self writeChar: ','];
	strToImasFormat(userName);
	[self writeString: userName qty: strlen(userName)];	
	[self writeChar: ','];	
	[self writeDateTime: [auditsRS getDateTimeValue:	"DATE"]];
	[self writeChar: ','];
	[auditsRS getStringValue: "ADDITIONAL" buffer:myTempBuffer];

  // Si tiene un valor en STATION lo concateno en el adicional
  if ([auditsRS getShortValue: "STATION"] != 0) {
    if (*myTempBuffer != 0) strcat(myTempBuffer, " - ");
    sprintf(station, "%d", [auditsRS getShortValue: "STATION"]);
    strcat(myTempBuffer, "CAB/PC: ");
    strcat(myTempBuffer, station);
  }

	strToImasFormat(myTempBuffer);
	[self writeString: myTempBuffer qty: strlen(myTempBuffer)];
	[self writeString: ")\xA" qty:2];
		

	return [self getLenInfo];	
}

/**/
- (int) formatDeposit: (char *) aBuffer
		includeDepositDetails: (BOOL) aIncludeDepositDetails
		deposits: (ABSTRACT_RECORDSET) aDepositRS
		depositDetails: (ABSTRACT_RECORDSET) aDepositDetailRS
{
	char line[512];
	char amountStr[50];
	int count = 0;
	char *systemId;
	money_t total = 0;
	unsigned long number;
	char dateStr[50];
	static char detail[4096];

	// Obtengo el id de sistema
	systemId	= [[TelesupFacade getInstance] getTelesupParamAsString: "SystemId" telesupRol: myTelesupId];

	[self setBuffer: aBuffer];
	number = [aDepositRS getLongValue: "NUMBER"];

	strcpy(detail, "");

	// Calcula y acumula los detalles en primer lugar porque de ahi obtiene
	// la cantidad de detalles y el total del deposito (que no tiene sentido
	// que vaya ni siquiera porque hay un total por moneda o validador que
	// hay que considerar)

	while (![aDepositDetailRS eof] && [aDepositDetailRS getLongValue: "NUMBER"] == number) {

			sprintf(line, "P_INS_TRAF_LLAMADA_CT8016DT(%s,'%ld','%s',%s,%d,%d)\xA",
				systemId,	// Id de punto de venta
				number,		// Numero de deposito
				"0000",		// Prefijo
				formatMoney(amountStr, "", [aDepositDetailRS getMoneyValue: "AMOUNT"], 6, 15),		// Denominacion
				[aDepositDetailRS getShortValue: "QTY"],		// Cantidad
				0		// Es moneda ?
			);

		total += [aDepositDetailRS getMoneyValue: "AMOUNT"] * [aDepositDetailRS getShortValue: "QTY"];
		count++;

		strcat(detail, line);

		[aDepositDetailRS moveNext];

	}

	// Escribe el encabezado
	sprintf(line, "P_INS_TRAF_LLAMADA_CT8016_DEP(%s,'%s','%s','%s','%ld',%d,%s)\xA",
		systemId,																															// Id de punto de venta
		convertDateTime(dateStr, [aDepositRS getDateTimeValue: "CLOSE_TIME"]),	// Fecha/hora de deposito
		[[[UserManager getInstance] getUserFromCompleteList: [aDepositRS getLongValue: "USER_ID"]] getLoginName],// Usuario
		"0000",																																// Prefijo
		number,																																// Numero
		count,																																// Cantidad de detalle
		formatMoney(amountStr,"",total,6,15)																	// Monto total
	);

	[self writeText: line];

	[self writeText: detail];

	//doLog(0,"%s", line);
	//doLog(0,"%s", detail);

	return [self getLenInfo];	
}

/**/
- (int) formatZClose: (char *) aBuffer
		includeZCloseDetails: (BOOL) aIncludeZCloseDetails
		zclose: (ABSTRACT_RECORDSET) aZCloseRS
{
	return 0;	
}

/**/
- (int) formatXClose: (char *) aBuffer
		includeXCloseDetails: (BOOL) aIncludeXCloseDetails
		xclose: (ABSTRACT_RECORDSET) aXCloseRS
{
	return 0;	
}

/**/
- (int) formatUser: (char *) aBuffer
		user: (id) aUser
{
	return 0;
}

@end
