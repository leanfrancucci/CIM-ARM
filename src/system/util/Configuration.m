#include <strings.h>
#include "Configuration.h"
#include "UtilExcepts.h"
#include "StringTokenizer.h"

@implementation Configuration

static CONFIGURATION singleInstance = NULL;

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	items = [Collection new];
	return self;
}

/**/
+ getDefaultInstance
{
	if (singleInstance) return singleInstance;
	singleInstance = [[self new] initWithFileName: "config.ini"];
	return singleInstance;
}

/**/
- free
{
	int i;

	// Libero las estructuras creadas
	for (i = 0; i < [items size]; ++i) {
		free( [items at:i] );
	}
	[items free];

	return [super free];
}

/**/
- initWithFileName: (char*) aFileName
{
	ConfigurationItem *item;
	STRING_TOKENIZER tokenizer = [StringTokenizer new];
	FILE *f;
	char buffer[255];
	char *index;
	
	[tokenizer setDelimiter: "="];
	[tokenizer setTrimMode: TRIM_ALL];
	
	f = fopen(aFileName, "r");
	if (!f) THROW_MSG(INVALID_CONFIGURATION_FILE_EX, aFileName);
	
	// en primer lugar, recorro el archivo para saber cuantos campos hay
	while (!feof(f)) {
		
		if (!fgets(buffer, 255, f)) break;
	
		if (buffer[0] == '#') continue;
		if (buffer[0] == '\n') continue;
		
		[tokenizer restart];
		[tokenizer setText: buffer];

		item = malloc(sizeof(ConfigurationItem));

		// Nombre
		if (![tokenizer hasMoreTokens]) THROW(INVALID_CONFIGURATION_FILE_EX);
		[tokenizer getNextToken: item->name];
		
		// Valor
		if (![tokenizer hasMoreTokens]) THROW(INVALID_CONFIGURATION_FILE_EX);
		[tokenizer getNextToken: item->value];

		// Saco los enters del final
		index = strchr(item->value, 13);
		if (index) *index = 0;
		index = strchr(item->value, 10);
		if (index) *index = 0;
		
		// testea la llamada
		[items add: item];
		
	}
	
	[tokenizer free];
	fclose(f);

	return self;
}

/**/
- (ConfigurationItem*) findItem: (char*) aName
{
	ConfigurationItem *item;
	int i;

	for (i = 0; i < [items size]; ++i) {
		item = (ConfigurationItem*)[items at: i];
		if (strcasecmp(aName, item->name) == 0) return item;
	}
	
	THROW_MSG(CONFIGURATION_NOT_FOUND_EX, aName);
	return NULL;
}

/**/
- (char*) getItemFromPosition: (int) aItemPos name: (char*) aName
{
	ConfigurationItem *item;

	if (aItemPos > [items size] - 1) THROW(CONFIGURATION_NOT_FOUND_EX);
	 
	item = (ConfigurationItem*)[items at: aItemPos];
	strcpy(aName, item->name);
	return aName;
}

/**/
- (int) getItemsQty
{
	return [items size];
}
- (char*) getParamAsString: (char*) aName
{
	ConfigurationItem *item;
	item = [self findItem: aName];
	return item->value;
}

/**/
- (long) getParamAsLong: (char*) aName
{
	ConfigurationItem *item;
	item = [self findItem: aName];
	return atol(item->value);
}

/**/
- (int) getParamAsInteger: (char*) aName
{
	return [self getParamAsShort: aName];
}

/**/
- (short) getParamAsShort: (char*) aName
{
	ConfigurationItem *item;
	item = [self findItem: aName];
	return atoi(item->value);
}

/**/
- (char*) getParamAsString: (char*) aName default: (char*) aDefault
{
	char *value;
	
	TRY
		value = [self getParamAsString: aName];
	CATCH
		value = aDefault;
	END_TRY

	return value;
}

/**/
- (long) getParamAsLong: (char*) aName default: (long) aDefault
{
	long value;
	
	TRY
		value = [self getParamAsLong: aName];
	CATCH
		value = aDefault;
	END_TRY

	return value;
}

/**/
- (short) getParamAsShort: (char*) aName default: (short) aDefault
{
	short value;
	
	TRY
		value = [self getParamAsShort: aName];
	CATCH
		value = aDefault;
	END_TRY

	return value;
}

/**/
- (int) getParamAsInteger: (char*) aName default: (int) aDefault
{
	int value;
	
	TRY
		value = [self getParamAsInteger: aName];
	CATCH
		value = aDefault;
	END_TRY

	return value;
}

/**/
- (void) getParamAsMoney: (char*) aName integer: (int*) integer decimal: (int*) decimal
{
	ConfigurationItem *item;
	char token[10];
	STRING_TOKENIZER tokenizer = [StringTokenizer new];
	
	item = [self findItem: aName];
	
	[tokenizer setDelimiter: "."];
	[tokenizer setTrimMode: TRIM_ALL];

	[tokenizer restart];
	[tokenizer setText: item->value];
	
	// Parte entera
	if (![tokenizer hasMoreTokens]) *integer = 0;
	[tokenizer getNextToken: token];
	*integer = atoi(token);
	
	// Parte decimal
	if (![tokenizer hasMoreTokens]) *decimal = 0;
	[tokenizer getNextToken: token];
	*decimal = atoi(token);
	
	[tokenizer free];		
}


@end
