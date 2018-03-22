#include "Operation.h"
#include "OperationDAO.h"
#include "SettingsExcepts.h"
#include "system/db/all.h"
#include "integer.h"
#include "util.h"
#include "Configuration.h"
#include "Collection.h"

static id singleInstance = NULL;

@implementation OperationDAO

- (id) newOpFromRecordSet: (id) aRecordSet; 

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- initialize
{
	[super initialize];
	return self;
}

/**/
- free
{
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}


/*
 *	Devuelve la configuracion de las operaciones en base a la informacion del registro actual del recordset.
 */

- (id) newOpFromRecordSet: (id) aRecordSet
{
	OPERATION obj;
	char buffer[101];

	obj = [Operation new];


	[obj setOperationId: [aRecordSet getShortValue: "OPERATION_ID"]];
	[obj setOpName: [aRecordSet getStringValue: "NAME" buffer: buffer]];
	[obj setOpResource: [aRecordSet getStringValue: "RESOURCE" buffer: buffer]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];

	return obj;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "operations" filter: "" orderFields: "OPERATION_ID"];
	OPERATION obj;

	[myRecordSet open];

	while ( [myRecordSet moveNext] ) {
		// agrego la operacion a la coleccion solo si no se encuentra borrado
		obj = [self newOpFromRecordSet: myRecordSet];
		if (!( [obj isDeleted]) ) [collection add: obj];
		else [obj free];
	}

	[myRecordSet free];
	return collection;
}

/**/

- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "operations" filter: "" orderFields: "OPERATION_ID"];
	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "OPERATION_ID" value: anId]) {
		obj = [self newOpFromRecordSet: myRecordSet];
		//Verifica que la operacion no este borrada
		if (![obj isDeleted])	return obj;
	} 
	[myRecordSet free];
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

@end
