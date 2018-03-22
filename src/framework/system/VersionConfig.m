#include "VersionConfig.h"
#include "telecom/TCTariffTable.h"
#include "StandardTariffTable.h"

@implementation VersionConfig

static VERSION_CONFIG singleInstance = NULL;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [[super new] initialize];
	return singleInstance;
}

/**/
- initialize
{
	versionType = 1;
	return self;
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- initWithVersionType: (int) aVersionType
{
	versionType = aVersionType;

	switch (versionType) {

		case VersionType_DELSAT:	
						strcpy(tariffTableExtension, "tec");
						tariffTableClass = [StandardTariffTable class];
						strcpy(versionTypeName, "DELSAT");
						break;
						
		case VersionType_TELEFONICA: 
						strcpy(tariffTableExtension, "tec");
						tariffTableClass = [StandardTariffTable class];
						strcpy(versionTypeName, "TELEFONICA");
						break;
						
		case VersionType_TELECOM: 
						strcpy(tariffTableExtension, "sup");
						tariffTableClass = [TCTariffTable class];
						strcpy(versionTypeName, "TELECOM");
						break;

		case VersionType_ECUADOR: 
						strcpy(tariffTableExtension, "tec");
						tariffTableClass = [StandardTariffTable class];
						strcpy(versionTypeName, "ECUADOR");
						break;
	
		case VersionType_OXXO: 
						strcpy(tariffTableExtension, "tec");
						tariffTableClass = [StandardTariffTable class];
						strcpy(versionTypeName, "OXXO");
						break;

	}
	
	return self;
}

/**/
- (char*) getTariffTableExtension
{
	return tariffTableExtension;
}

/**/
- (int) getVersionType
{
	return versionType;
}

/**/
- (char*) getVersionTypeName
{
	return versionTypeName;	
}

/**/
- getTariffTableClass
{
	return tariffTableClass;
}

/**/
- (int) mapCallType: (char*)aPhone callType: (int) aCallType
{
	if (versionType != TELECOM) return aCallType;

	// En forma cableado me fijo si es 00, retorno internacional, con 0 nacional
	// 255 en otro caso

	if (strstr(aPhone, "000") == aPhone) return 99;	// Por operadora
	if (strstr(aPhone, "00") == aPhone) return 2;		// Internacional
	if (strstr(aPhone, "0") == aPhone) return 1;		// Nacional

	return 255;
}

/**/
- (BOOL) isValidTable: (TARIFF_TABLE) aTariffTable
{
	COLLECTION files;
	char fileName[255];
	char buf[255];
	FILE *f;
	int i;
	BOOL found = FALSE;
	char file1[100];
	char file2[100];
	char *tableName;
	char *path;

	// Para telefonica y Delsat siempre es valida la tabla
	if (versionType != TELECOM) {
		return TRUE;
	}

	// Para Telecom me tengo que fijarme en el TABLAS.TEL
	// Si esta en tablas.tel entonces es valida, en caso contrario no
	// Levanto el archivo TABLAS.TEL y lo lentanto a una coleccion
	// Despues analizo si el archivo pasado por parametro esta en esa coleccion
	// para determinar si es valida o no.

	files = [Collection new];
	sprintf(fileName, "%s/%s", [[Configuration getDefaultInstance] getParamAsString: "TABLE_PATH"], "TABLAS.TEL");
	f = fopen(fileName, "r");

	if (!f) {
	//	doLog(0,"Error al intentar abrir el archivo %s\n", fileName);
		return FALSE;
	}
	
	while (!feof(f))
	{
		if (!fgets(buf, 100, f)) break;
		if (*buf == 0) break;

		buf[17] = 0;

		tableName = malloc(8+3+1+1);	// Nombre(8).(1)Extension(3)+\n(1)
		strncpy(tableName, buf, 12);
		tableName[12] = 0;

		[files add: tableName];

	}

	for (i = 0; i < [files size]; ++i) {

		if (strrchr([aTariffTable getFileName], '/') == NULL) {
		//	doLog(0,"VersionConfig -> Deberia encontrar un / en %s\n", [aTariffTable getFileName]);
			strcpy(file1, [aTariffTable getFileName]);
		} else
			strcpy(file1, strrchr([aTariffTable getFileName], '/') + 1);

		if (strcasecmp(file1, (char*)[files at: i]) == 0) {
			found = TRUE;
			break;
		}

	}

	// Elimino la lista
	for (i = 0; i < [files size]; ++i) {
		path = (char*)[files at: i];
		free(path);
	}

	[files free];
	fclose(f);

	return found;
}


@end
