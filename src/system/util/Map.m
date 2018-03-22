#include <strings.h>
#include "Map.h"
#include "UtilExcepts.h"
#include "util.h"

@implementation Map


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
- free
{
  MapItem *item;
	int i;

	// Libero las estructuras creadas
	for (i = 0; i < [items size]; ++i) {
	  item = (MapItem*) [items at: i]; 
	  if (item->text != NULL) free(item->text);
	  
  	free( [items at:i] );
	}
	
	[items free];

	return [super free];
}

/**/
- (int) getItemCount
{
	return [items size];
}

/**/
- (char *) getItemNameAt: (int) anIndex
{
	MapItem *item;
	if (anIndex >= [self getItemCount]) THROW_FMT(INDEX_OUT_OF_BOUNDS_EX, "%d,%d", anIndex, [self getItemCount]);

	item = (MapItem*)[items at: anIndex];
	return item->name;
}

/**/
- (void) addParamAsCurrency: (char *) aName value: (money_t) aValue
{
 	[self addParamAsCurrency: aName value: aValue decimals: 6];
}

/**/
- (void) addParamAsCurrency: (char *) aName value: (money_t) aValue decimals: (int) aDecimals
{
	char amountstr[50];
	[self addParamAsString: aName value: formatMoney(amountstr, "", aValue, aDecimals, 50)];
};

/**/
- (void) addParamAsDateTime: (char*) aName value: (datetime_t) aValue
{
	char buf[MAX_MAP_VALUE];
	datetimeToISO8106(buf, aValue);
	[self addParamAsString: aName value: buf];
}

/**/
- (void) addParamAsLong: (char*) aName value: (long) aValue
{
	char buf[MAX_MAP_VALUE];
	sprintf(buf, "%ld", aValue);
	[self addParamAsString: aName value: buf];
}

/**/
- (void) addParamAsInteger: (char*) aName value: (int) aValue
{
	char buf[MAX_MAP_VALUE];
	sprintf(buf, "%d", aValue);
	[self addParamAsString: aName value: buf];
}

/**/
- (void) addParamAsString: (char*) aName value: (char*) aValue
{
	MapItem *item = malloc(sizeof(MapItem));
	stringcpy(item->name, aName);
	stringcpy(item->value, aValue);
	/*ale*/
	item->text = NULL;
	[items add: item];
}

/**/
- (void) addParamAsFloat: (char *)aName value: (float) aValue
{
	char buf[MAX_MAP_VALUE];
	sprintf(buf, "%.6f", aValue);
	[self addParamAsString: aName value: buf];
}


/**/
- (void) addParamAsBoolean: (char*) aName value: (BOOL) aValue
{
	char buf[MAX_MAP_VALUE];
	strcpy(buf, aValue ? "True" : "False");
	[self addParamAsString: aName value: buf];
}

/**/
- (void) addParamAsText: (char*) aName value: (char*) aValue
{
	MapItem *item = malloc(sizeof(MapItem));
	stringcpy(item->name, aName);	
	item->text = strdup(fillTextSpecialCharacter(aValue, doc));
	[items add: item];
}

/**/
- (MapItem*) findItem: (char*) aName
{
	MapItem *item;
	int i;

	for (i = 0; i < [items size]; ++i) {
		item = (MapItem*)[items at: i];
		if (strcasecmp(aName, item->name) == 0) return item;
	}
	
	THROW_MSG(CONFIGURATION_NOT_FOUND_EX, aName);
	return NULL;
}

/**/
- (char*) getParamAsString: (char*) aName
{
	MapItem *item;
	item = [self findItem: aName];
	/*ale*/
	if (item->text != NULL) return item->text;
	return item->value;
}

/**/
- (char*) getParamAsText: (char*) aName
{
  /*ale*/
	MapItem *item;
	item = [self findItem: aName];
	return item->text;
}

/**/
- (long) getParamAsLong: (char*) aName
{
	MapItem *item;
	item = [self findItem: aName];
	return atol(item->value);
}

/**/
- (float) getParamAsFloat: (char*) aName
{
	MapItem *item;
	item = [self findItem: aName];
	return atof(item->value);
}

/**/
- (int) getParamAsInteger: (char*) aName
{
	return [self getParamAsShort: aName];
}

/**/
- (short) getParamAsShort: (char*) aName
{
	MapItem *item;
	item = [self findItem: aName];
	return atoi(item->value);
}

/**/
- (BOOL) getParamAsBoolean: (char*) aName
{
	MapItem *item;
	item = [self findItem: aName];
	return strcmp(item->value, "True") == 0;
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
- (float) getParamAsFloat: (char*) aName default: (float) aDefault
{
	float value;
	
	TRY
		value = [self getParamAsFloat: aName];
	CATCH
		value = aDefault;
	END_TRY

	return value;
}

/**/
- (BOOL) getParamAsBoolean: (char*) aName default: (BOOL) aDefault
{
	BOOL value;
	
	TRY
		value = [self getParamAsBoolean: aName];
	CATCH
		value = aDefault;
	END_TRY

	return value;
}

@end
