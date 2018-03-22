#include <assert.h>
#include "SQLField.h"
#include "SQLWrapper.h"
#include "system/util/all.h"
#include "expat.h"

// Algunos defines para que quede todo prolijo
#define FIELDS_TAG	"fields"
#define ROW_TAG		"row"
#define FIELD_TAG	"name"
#define	FIELD_NAME_ATT_POS	1
#define FIELD_TYPE_ATT_POS  5
#define FIELD_SIZE_ATT_POS	7
#define FIELD_SCALE_ATT_POS 9

/**/
typedef struct {
	char *currentRow;
	int   currentField;
	int	  recordCount;
	int	  inRow;
	int   inData;
	int	  inMetadata;
	char  currentFieldName[255];
	int	  recordSize;
	COLLECTION rows;
	COLLECTION fields;
} XMLUserData;

/**/
static SQLField *
getFieldByPos(XMLUserData *udata, int pos) 
{ 
	return (SQLField *)[udata->fields at: pos]; 
}

/**/
static SQLType 
mapDataType(FBSQLType fieldType)
{

	switch (fieldType) {
		case FBSQLType_DATE:
		case FBSQLType_TIME:
		case FBSQLType_TIMESTAMP:
			return SQLType_DATETIME;

		case FBSQLType_STRING:
			return SQLType_STRING;

		case FBSQLType_SMALL_INT:
		case FBSQLType_INTEGER:
			return SQLType_INTEGER;

		case FBSQLType_NUMERIC:
		case FBSQLType_FLOAT:
		case FBSQLType_DOUBLE:
			return SQLType_MONEY;
	}

	assert(1);
	return SQLType_INTEGER;
}

static int 
mapFieldSize(FBSQLType fieldType, int fieldSize)
{

	switch (fieldType) {
		case FBSQLType_DATE:
		case FBSQLType_TIME:
		case FBSQLType_TIMESTAMP:
			return sizeof(datetime_t);

		default:
			return fieldSize;
	}

	return fieldSize;
}

/**
 *	Agrego el campo a la lista de campos
 */
static void 
addField(XMLUserData *udata, const char *name, int fieldType, int fieldSize, int fieldScale)
{
	SQLField *field = malloc(sizeof(SQLField));
	int size;

//	doLog(0,"new field[%d] = %s, %d, %d, %d\n", currentField, name, fieldType, size, fieldScale);
	strcpy(field->fieldName, name);
	rtrim(field->fieldName);
	size = mapFieldSize(fieldType,fieldSize);
	field->fieldSize   = size;
	field->fieldOffset = udata->recordSize;
	field->fieldType   = mapDataType(fieldType);
	field->fieldScale  = fieldScale;
	field->fieldIsPK   = FALSE;

	[udata->fields add: field];

	udata->recordSize += size;
	udata->currentField++;
}

/**
 *
 */
static void 
addRow(XMLUserData *udata)
{
	udata->inRow = 1;
	udata->currentField = 0;
	udata->recordCount++;
	udata->currentRow   = malloc(udata->recordSize);
  memset(udata->currentRow, 0, udata->recordSize);
	[udata->rows add: udata->currentRow];
}

/**/
static void XMLCALL
startElement(void *userData, const char *name, const char **atts)
{
  XMLUserData *udata = (XMLUserData*)userData;

  // Comienza el tag <fields>, marco como que estoy en la seccion metadata
  if (strcmp(name, FIELDS_TAG) == 0) {
	udata->inMetadata = 1;
	return;
  }

  // Comienza un tag <row>, agrego la fila
  if (strcmp(name, ROW_TAG) == 0) {
	addRow(udata);
	return;
  }

  // Comienza el tag de campo y estoy en metadatos, agrego el campo
  if (udata->inMetadata && strcmp(name, FIELD_TAG) == 0) {
	addField(udata, atts[FIELD_NAME_ATT_POS], atoi(atts[FIELD_TYPE_ATT_POS]), 
					atoi(atts[FIELD_SIZE_ATT_POS]), atoi(atts[FIELD_SCALE_ATT_POS]));
	return;
  }

  // Estoy dentro de una fila, cualquier tag es el nombre del campo y luego llegara el valor
  // a traves del dataHandler
  if (udata->inRow) {
	strcpy(udata->currentFieldName, name);
    return;
  }

}

/**/
static void XMLCALL
endElement(void *userData, const char *name)
{
  XMLUserData *udata = (XMLUserData*)userData;

  // Termino el tag <fields>
  if (strcmp(name, FIELDS_TAG) == 0) {
	udata->inMetadata = 0;
	return;
  }

  // Termino la fila
  if (strcmp(name, ROW_TAG) == 0) {
	udata->inRow = 0;
	return;
  }

}

/**/
void addData(XMLUserData *udata, int fieldPos, const char *s, int len)
{
	char data[255];
	long lvalue;
	short svalue;
	SQLField *field;
	char *p;
	char cvalue;
	money_t mvalue;
	datetime_t time;
	int year, mon, day, hour, min, sec;
	unsigned char *pdata = data;
	int spchar = 0;
	
	field = getFieldByPos(udata, fieldPos);
	
	p = &udata->currentRow[field->fieldOffset];
	strncpy(data, s, len);
	data[len]=0;

	
	switch (field->fieldType) {

		case SQLType_BOOL:
			cvalue = atoi(data);
			memcpy(p, &cvalue, field->fieldSize);
			break;
			
		case SQLType_INTEGER:
		case SQLType_AUTOINC:
			assert(field->fieldSize==2 || field->fieldSize==4);
			if (field->fieldSize == 2) {
				svalue = atoi(data);
				memcpy(p, &svalue, sizeof(svalue));
			} else {
				lvalue = atol(data);
				memcpy(p, &lvalue, sizeof(lvalue));
			}
			break;

		case SQLType_MONEY: 
			mvalue = stringToMoney(data);
			memcpy(p, &mvalue, sizeof(money_t));
			break;

		case SQLType_STRING:
		case SQLType_CHAR:
			
			data[field->fieldSize] = 0;
			while (*pdata) {
				if (*pdata != (unsigned char)'\xC3') {
					if (*pdata + (spchar * 64) > 255) *p = '?';
					else *p = *pdata + (spchar * 64);
					p++;
					spchar = 0;
				} else {
					spchar = 1;
				}
				
				pdata++;
			}
			
			*p = '\0';
			
			//memcpy(p, data, field->fieldSize);
			
			break;

		case SQLType_DATETIME:
			sscanf(data, "%04d-%02d-%02d %02d:%02d:%02d", &year, &mon, &day, &hour, &min, &sec);
			time = [SystemTime encodeTime: year mon: mon day: day  hour: hour min: min sec: sec];
      time = [SystemTime convertToLocalTime: time];
			memcpy(p, &time, sizeof(datetime_t));
			break;

		default: assert(1);

	}

//	doLog(0,"%s=%s byte = %d\n", fieldName, data, getFieldOffset(udata->currentField));
}

/**/
static void dataHandler (void *userData, const XML_Char *s, int len)
{
	XMLUserData *udata = (XMLUserData*)userData;
	int fieldPos = atoi(&udata->currentFieldName[1])-1;
  addData(udata, fieldPos, s, len);
	udata->currentField++;
}

/**/
int parseXMLResults(char *buf, int len, COLLECTION fields, COLLECTION rows)
{
  XMLUserData udata;
  XML_Parser parser;
  
  parser = XML_ParserCreate(NULL);
  
  udata.currentField = 0;
  udata.recordCount = 0;
  udata.rows = rows;
  udata.recordSize = 0;
  udata.fields = fields;

  XML_SetUserData(parser, &udata);
  XML_SetElementHandler(parser, startElement, endElement);
  XML_SetCharacterDataHandler(parser, dataHandler);

  if (XML_Parse(parser, buf, len, TRUE) == XML_STATUS_ERROR) {
   /*   doLog(0,
              "%s at line %d\n",
              XML_ErrorString(XML_GetErrorCode(parser)),
              XML_GetCurrentLineNumber(parser));*/
      return 1;
  }

  XML_ParserFree(parser);

  return 0;
}

/**********************************************************************
 * PARSING DE PRIMARY KEYS DE LA TABLA
 *********************************************************************/ 

static void XMLCALL
pkStartElement(void *userData, const char *name, const char **atts)
{
}

/**/
static void XMLCALL 
pkEndElement(void *userData, const char *name)
{
}

/**/
static void pkDataHandler (void *userData, const XML_Char *s, int len)
{
	COLLECTION fields = userData;
	SQLField *field;
	int i;
  char buf[255];
 
  strncpy(buf, s, len);
  buf[len-1] = 0;
  rtrim(buf);
  
	for (i = 0; i < [fields size]; i++) {
    field = (SQLField*)[fields at: i];
    if (strcasecmp(field->fieldName, buf) != 0) continue;
    //doLog(0,"field |%s| is primary key\n", buf);    
    field->fieldIsPK = TRUE;
  }

}


/**/
int parsePrimaryKeys(char *buf, int len, COLLECTION fields)
{
  XML_Parser parser;
  
  parser = XML_ParserCreate(NULL);

  XML_SetUserData(parser, fields);
  XML_SetElementHandler(parser, pkStartElement, pkEndElement);
  XML_SetCharacterDataHandler(parser, pkDataHandler);

  if (XML_Parse(parser, buf, len, TRUE) == XML_STATUS_ERROR) {
      /*doLog(0,
              "%s at line %d\n",
              XML_ErrorString(XML_GetErrorCode(parser)),
              XML_GetCurrentLineNumber(parser));*/
      return 1;
  }
  XML_ParserFree(parser);

  return 0;  
}
