#ifndef VERSION_CONFIG_H
#define VERSION_CONFIG_H

#define VERSION_CONFIG id

#include <Object.h>
#include "ctapp.h"
#include "TariffTable.h"

/**
 *	Tipos de versiones soportadas
 */
enum {
	VersionType_UNKNOWN
	VersionType_DELSAT,
	VersionType_TELEFONICA,
	VersionType_TELECOM,
	VersionType_ECUADOR,
  VersionType_OXXO
};

/**
 *	Configuracion de la version.
 *	
 */
@interface VersionConfig : Object
{
	int 		versionType;
	id 			tariffTableClass;
	char 		tariffTableExtension[6];
	char 		versionTypeName[30];
}

/**/
- initWithVersionType: (int) aTelcoType;

/**/
+ getInstance;

/**/
- (int) getVersionType;

/**/
- (char*) getTariffTableExtension;

/**/
- getTariffTableClass;

/**/
- (char*) getVersionTypeName;

/**
 *	Mapea el tipo de llamada para las distintas prestadoras.
 *	Se le pasa por parametro el tipo de llamada encontrado por tabla y el numero
 *	telefonica, y devuelve el tipo de llamada mapeado.
 */
- (int) mapCallType: (char*)aPhone callType: (int) aCallType;

/**
 *
 */
- (BOOL) isValidTable: (TARIFF_TABLE) aTariffTable;

@end

#endif
