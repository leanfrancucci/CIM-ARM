#include "JCommercialStCodeForm.h"
#include "MessageHandler.h"
#include "StringTokenizer.h"
#include "JMessageDialog.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "CimGeneralSettings.h"

//#define printd(args...) doLog(args)
#define printd(args...)

static char myBackMessage[] = "atras";
static char myEnterMessage[] = "entrar";

@implementation JCommercialStCodeForm

- (BOOL) validateCode: (char*) aText;
- (void) generateReport;
- (int) getTextLength;

/**/
- (void) initComponent
{
	[super initComponent];
	*myTitle = '\0';
	*myTextCode = '\0';
  myViewMode = TRUE;
	myROnly = FALSE;
	myLenghtText = 16;
	chrCount = 0;
  myCurrentPosition = 1;
  myCanPressSpace = FALSE;
  myViewBackOption = TRUE;
}

/**/
- (void) doOpenForm
{
	[super doOpenForm];
	
	if (*myTitle != '\0') {
		myLabelTitle = [self addLabel: myTitle];
	}

	// bloque 1	
  myLabelBlok1 = [JLabel new];
	[myLabelBlok1 setWidth: 4];
	[myLabelBlok1 setAutoSize: FALSE];
	[myLabelBlok1 setCaption: "1 : "];
	[self addFormComponent: myLabelBlok1];

	myTextBlok1 = [JText new];
	[myTextBlok1 setWidth: myLenghtText];
	[myTextBlok1 setNumericMode: TRUE];
	[myTextBlok1 setNumericType: JTextNumericType_CODE];  
	[myTextBlok1 setText: ""];
  [myTextBlok1 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok1];

  [self addFormEol];

	// bloque 2	
  myLabelBlok2 = [JLabel new];
	[myLabelBlok2 setWidth: 4];
	[myLabelBlok2 setAutoSize: FALSE];
	[myLabelBlok2 setCaption: "2 : "];
	[self addFormComponent: myLabelBlok2];

	myTextBlok2 = [JText new];
	[myTextBlok2 setWidth: myLenghtText];
	[myTextBlok2 setNumericMode: TRUE];
	[myTextBlok2 setNumericType: JTextNumericType_CODE];  
	[myTextBlok2 setText: ""];
  [myTextBlok2 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok2];

  [self addFormEol];

	// bloque 3	
  myLabelBlok3 = [JLabel new];
	[myLabelBlok3 setWidth: 4];
	[myLabelBlok3 setAutoSize: FALSE];
	[myLabelBlok3 setCaption: "3 : "];
	[self addFormComponent: myLabelBlok3];

	myTextBlok3 = [JText new];
	[myTextBlok3 setWidth: myLenghtText];
	[myTextBlok3 setNumericMode: TRUE];
	[myTextBlok3 setNumericType: JTextNumericType_CODE];  
	[myTextBlok3 setText: ""];
  [myTextBlok3 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok3];

  [self addFormEol];

	// bloque 4	
  myLabelBlok4 = [JLabel new];
	[myLabelBlok4 setWidth: 4];
	[myLabelBlok4 setAutoSize: FALSE];
	[myLabelBlok4 setCaption: "4 : "];
	[self addFormComponent: myLabelBlok4];

	myTextBlok4 = [JText new];
	[myTextBlok4 setWidth: myLenghtText];
	[myTextBlok4 setNumericMode: TRUE];
	[myTextBlok4 setNumericType: JTextNumericType_CODE];  
	[myTextBlok4 setText: ""];
  [myTextBlok4 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok4];

  [self addFormEol];

	// bloque 5	
  myLabelBlok5 = [JLabel new];
	[myLabelBlok5 setWidth: 4];
	[myLabelBlok5 setAutoSize: FALSE];
	[myLabelBlok5 setCaption: "5 : "];
	[self addFormComponent: myLabelBlok5];

	myTextBlok5 = [JText new];
	[myTextBlok5 setWidth: myLenghtText];
	[myTextBlok5 setNumericMode: TRUE];
	[myTextBlok5 setNumericType: JTextNumericType_CODE];  
	[myTextBlok5 setText: ""];
  [myTextBlok5 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok5];

  [self addFormEol];

	// bloque 6	
  myLabelBlok6 = [JLabel new];
	[myLabelBlok6 setWidth: 4];
	[myLabelBlok6 setAutoSize: FALSE];
	[myLabelBlok6 setCaption: "6 : "];
	[self addFormComponent: myLabelBlok6];

	myTextBlok6 = [JText new];
	[myTextBlok6 setWidth: myLenghtText];
	[myTextBlok6 setNumericMode: TRUE];
	[myTextBlok6 setNumericType: JTextNumericType_CODE];  
	[myTextBlok6 setText: ""];
  [myTextBlok6 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok6];

  [self addFormEol];

	// bloque 7	
  myLabelBlok7 = [JLabel new];
	[myLabelBlok7 setWidth: 4];
	[myLabelBlok7 setAutoSize: FALSE];
	[myLabelBlok7 setCaption: "7 : "];
	[self addFormComponent: myLabelBlok7];

	myTextBlok7 = [JText new];
	[myTextBlok7 setWidth: myLenghtText];
	[myTextBlok7 setNumericMode: TRUE];
	[myTextBlok7 setNumericType: JTextNumericType_CODE];  
	[myTextBlok7 setText: ""];
  [myTextBlok7 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok7];

  [self addFormEol];

	// bloque 8	
  myLabelBlok8 = [JLabel new];
	[myLabelBlok8 setWidth: 4];
	[myLabelBlok8 setAutoSize: FALSE];
	[myLabelBlok8 setCaption: "8 : "];
	[self addFormComponent: myLabelBlok8];

	myTextBlok8 = [JText new];
	[myTextBlok8 setWidth: myLenghtText];
	[myTextBlok8 setNumericMode: TRUE];
	[myTextBlok8 setNumericType: JTextNumericType_CODE];  
	[myTextBlok8 setText: ""];
  [myTextBlok8 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok8];

  [self addFormEol];

	// bloque 9	
  myLabelBlok9 = [JLabel new];
	[myLabelBlok9 setWidth: 4];
	[myLabelBlok9 setAutoSize: FALSE];
	[myLabelBlok9 setCaption: "9 : "];
	[self addFormComponent: myLabelBlok9];

	myTextBlok9 = [JText new];
	[myTextBlok9 setWidth: myLenghtText];
	[myTextBlok9 setNumericMode: TRUE];
	[myTextBlok9 setNumericType: JTextNumericType_CODE];  
	[myTextBlok9 setText: ""];
  [myTextBlok9 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok9];

  [self addFormEol];

	// bloque 10	
  myLabelBlok10 = [JLabel new];
	[myLabelBlok10 setWidth: 4];
	[myLabelBlok10 setAutoSize: FALSE];
	[myLabelBlok10 setCaption: "10: "];
	[self addFormComponent: myLabelBlok10];

	myTextBlok10 = [JText new];
	[myTextBlok10 setWidth: myLenghtText];
	[myTextBlok10 setNumericMode: TRUE];
	[myTextBlok10 setNumericType: JTextNumericType_CODE];  
	[myTextBlok10 setText: ""];
  [myTextBlok10 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok10];

  [self addFormEol];

	// bloque 11	
  myLabelBlok11 = [JLabel new];
	[myLabelBlok11 setWidth: 4];
	[myLabelBlok11 setAutoSize: FALSE];
	[myLabelBlok11 setCaption: "11: "];
	[self addFormComponent: myLabelBlok11];

	myTextBlok11 = [JText new];
	[myTextBlok11 setWidth: myLenghtText];
	[myTextBlok11 setNumericMode: TRUE];
	[myTextBlok11 setNumericType: JTextNumericType_CODE];  
	[myTextBlok11 setText: ""];
  [myTextBlok11 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok11];

  [self addFormEol];

	// bloque 12
  myLabelBlok12 = [JLabel new];
	[myLabelBlok12 setWidth: 4];
	[myLabelBlok12 setAutoSize: FALSE];
	[myLabelBlok12 setCaption: "12: "];
	[self addFormComponent: myLabelBlok12];

	myTextBlok12 = [JText new];
	[myTextBlok12 setWidth: myLenghtText];
	[myTextBlok12 setNumericMode: TRUE];
	[myTextBlok12 setNumericType: JTextNumericType_CODE];  
	[myTextBlok12 setText: ""];
  [myTextBlok12 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok12];

  [self addFormEol];

	// bloque 13
  myLabelBlok13 = [JLabel new];
	[myLabelBlok13 setWidth: 4];
	[myLabelBlok13 setAutoSize: FALSE];
	[myLabelBlok13 setCaption: "13: "];
	[self addFormComponent: myLabelBlok13];

	myTextBlok13 = [JText new];
	[myTextBlok13 setWidth: myLenghtText];
	[myTextBlok13 setNumericMode: TRUE];
	[myTextBlok13 setNumericType: JTextNumericType_CODE];  
	[myTextBlok13 setText: ""];
  [myTextBlok13 setReadOnly: myROnly];
	[self addFormComponent: myTextBlok13];

	[self focusFormFirstComponent];
	[self doChangeStatusBarCaptions];
}

/**/
- (void) onActivateForm
{
	// si es solo lectura es porque debo mostrar el codigo generado
	// sino muestra los edits en vacio
	if (myViewMode)
		myLenghtText = 16;
	else
		myLenghtText = 15;

	[myTextBlok1 setWidth: myLenghtText];
	[myTextBlok2 setWidth: myLenghtText];
	[myTextBlok3 setWidth: myLenghtText];
	[myTextBlok4 setWidth: myLenghtText];
	[myTextBlok5 setWidth: myLenghtText];
	[myTextBlok6 setWidth: myLenghtText];
	[myTextBlok7 setWidth: myLenghtText];
	[myTextBlok8 setWidth: myLenghtText];
	[myTextBlok9 setWidth: myLenghtText];
	[myTextBlok10 setWidth: myLenghtText];
	[myTextBlok11 setWidth: myLenghtText];
	[myTextBlok12 setWidth: myLenghtText];
	[myTextBlok13 setWidth: myLenghtText];

	// parseo el codigo
	[self parsingCode];

}

/**/
- (void) parsingCode
{

  STRING_TOKENIZER tokenizer;
  char token[10];
  int blockCount;
	int blockPos;
	char block[16];
  char blockaux[16];

	tokenizer = [[StringTokenizer new] initTokenizer: myTextCode delimiter: " "];

	blockCount = 0;
  blockPos = 0;
	block[0] = '\0';
  blockaux[0] = '\0';
	while ([tokenizer hasMoreTokens]) {

		[tokenizer getNextToken: token];

		blockCount++;

		if (blockCount == 4){
			blockCount = 0;
			blockPos++;

			if (strlen(token) != 0)
			  strcat(block, token);

			switch (blockPos) {
				case 1:  [myTextBlok1 setText: trim(block)]; break;
				case 2:  [myTextBlok2 setText: trim(block)]; break;
				case 3:  [myTextBlok3 setText: trim(block)]; break;
				case 4:  [myTextBlok4 setText: trim(block)]; break;
				case 5:  [myTextBlok5 setText: trim(block)]; break;
				case 6:  [myTextBlok6 setText: trim(block)]; break;
				case 7:  [myTextBlok7 setText: trim(block)]; break;
				case 8:  [myTextBlok8 setText: trim(block)]; break;
				case 9:  [myTextBlok9 setText: trim(block)]; break;
				case 10: [myTextBlok10 setText: trim(block)]; break;
				case 11: [myTextBlok11 setText: trim(block)]; break;
				case 12: [myTextBlok12 setText: trim(block)]; break;
				case 13: [myTextBlok13 setText: trim(block)]; break;
		  }

			block[0] = '\0';

		}else{
			blockaux[0] = '\0';
			if (strlen(token) != 0){
			  sprintf(blockaux, "%s ",token);
			  strcat(block, blockaux);
			}
	  }

	}
	
	// esto es porque la ultima linea puede que no ocupe todo el largo del bloque
	if (strlen(block) > 0){
			switch (blockPos) {
				case 0:  [myTextBlok1 setText: trim(block)]; break;
				case 1:  [myTextBlok2 setText: trim(block)]; break;
				case 2:  [myTextBlok3 setText: trim(block)]; break;
				case 3:  [myTextBlok4 setText: trim(block)]; break;
				case 4:  [myTextBlok5 setText: trim(block)]; break;
				case 5:  [myTextBlok6 setText: trim(block)]; break;
				case 6:  [myTextBlok7 setText: trim(block)]; break;
				case 7:  [myTextBlok8 setText: trim(block)]; break;
				case 8:  [myTextBlok9 setText: trim(block)]; break;
				case 9:  [myTextBlok10 setText: trim(block)]; break;
				case 10: [myTextBlok11 setText: trim(block)]; break;
				case 11: [myTextBlok12 setText: trim(block)]; break;
				case 12: [myTextBlok13 setText: trim(block)]; break;
		  }
	}

	[tokenizer free];
}

/**/
- (void) setViewMode: (BOOL) aValue { myViewMode = aValue; }

/**/
- (void) setViewBackOption: (BOOL) aValue { myViewBackOption = aValue; }

/**/
- (char *) getTextCode
{ 
	myTextCode[0] = '\0';

	sprintf(myTextCode, "%s %s %s %s %s %s %s %s %s %s %s %s %s", 
					trim([myTextBlok1 getText]),
					trim([myTextBlok2 getText]),
					trim([myTextBlok3 getText]),
					trim([myTextBlok4 getText]),
					trim([myTextBlok5 getText]),
					trim([myTextBlok6 getText]),
					trim([myTextBlok7 getText]),
					trim([myTextBlok8 getText]),
					trim([myTextBlok9 getText]),
					trim([myTextBlok10 getText]),
					trim([myTextBlok11 getText]),
					trim([myTextBlok12 getText]),
					trim([myTextBlok13 getText]) );
	
  return trim(myTextCode);
}

- (void) setTextCode: (char *) aValue { stringcpy(myTextCode, aValue); }

/**/
- (void) setTitle: (char *) aTitle { stringcpy(myTitle, aTitle); }

/**/
- (void) onMenu1ButtonClick
{
  if (myViewBackOption){
		myModalResult = JFormModalResult_CANCEL;
		[self closeForm];
	}
}

/**/
- (void) onMenu2ButtonClick
{
	if (!myViewMode){

	  if ([self validateCode: [self getTextCode]]){
	    myModalResult = JFormModalResult_OK;
	    [self closeForm];
	  }else{
		  [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_ERROR_FORMAT_CODE, "Formato de codigo erroneo.")];
		}

  }else{
	    myModalResult = JFormModalResult_OK;
	    [self closeForm];
  }

}

/**/
- (void) onMenuXButtonClick
{
	if (!myViewMode){
		[super onMenuXButtonClick];
  }else{
		[self generateReport];
  }

}

/**/
- (char *) getCaption1
{
  if (myViewBackOption)
	  return getResourceStringDef(RESID_BACK_KEY, myBackMessage);
  else
		return NULL;
}

/**/
- (char *) getCaptionX
{
  if (myViewMode)
		return getResourceStringDef(RESID_PRINT, "imprime");
	else
	  return [super getCaptionX];
}

/**/
- (char *) getCaption2
{
  if (myViewBackOption)
		return getResourceStringDef(RESID_ENTER, myEnterMessage);
  else
		return getResourceStringDef(RESID_CLOSE_KEY, "cerrar");
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
	BOOL pressX;

	if (!anIsPressed)
			return FALSE;

	if (myViewMode){
	
		// Si es alguna de las teclas especiales entonces las procesa
		switch (aKey) {

			case UserInterfaceDefs_KEY_MENU_1:
				return [super doKeyPressed: aKey isKeyPressed: anIsPressed]; break;

			case UserInterfaceDefs_KEY_MENU_2:
				return [super doKeyPressed: aKey isKeyPressed: anIsPressed]; break;

			case UserInterfaceDefs_KEY_MENU_X:
				[self onMenuXButtonClick]; 
				return FALSE;
				break;

			case UserInterfaceDefs_KEY_UP:
				return [super doKeyPressed: aKey isKeyPressed: anIsPressed]; break;

			case UserInterfaceDefs_KEY_DOWN:
				return [super doKeyPressed: aKey isKeyPressed: anIsPressed]; break;
		}

		return FALSE;

  }else{

		if ((aKey == UserInterfaceDefs_KEY_LEFT) || (aKey == UserInterfaceDefs_KEY_RIGHT))
			 return FALSE;
	
		if ((aKey == 32) && (!myCanPressSpace))
		   return FALSE;
		
		myCanPressSpace = FALSE;
		pressX = FALSE;

		// si es el ultimo caracter bajo al edit siguiente
		if ((aKey >= 48) && (aKey <= 57)){
		  if (chrCount == 15){
			  chrCount = 0;
			  [self doKeyPressed: UserInterfaceDefs_KEY_DOWN isKeyPressed: TRUE];
		  }
		}

		// si es un caracter incremento la posicion del cursor
		if ((aKey >= 48) && (aKey <= 57))
				chrCount++;
		// si borra un caracter decremento la posicion del cursor
		if (aKey == UserInterfaceDefs_KEY_MENU_X){
			pressX = TRUE;
			if (chrCount > 0)
				chrCount--;

			if ([self getTextLength] == 1)
				chrCount = 0;
		}

		// incremento la posicion del edit actual
		if (aKey == UserInterfaceDefs_KEY_DOWN){
			if (myCurrentPosition < 13)
        myCurrentPosition++;
		}
		// decremento la posicion del edit actual
		if (aKey == UserInterfaceDefs_KEY_UP){
      if (myCurrentPosition > 1)
			  myCurrentPosition--;
		}

		// obtengo el largo del texto actual
		if ((aKey == UserInterfaceDefs_KEY_UP) || (aKey == UserInterfaceDefs_KEY_DOWN)){
			chrCount = [self getTextLength];
		}

		if ((chrCount == 4) || (chrCount == 8) || (chrCount == 12)){
			if (!pressX){
			  chrCount++;
				myCanPressSpace = TRUE;
		    [self doKeyPressed: 32 isKeyPressed: TRUE];
			}
		}

    return [super doKeyPressed: aKey isKeyPressed: anIsPressed];
	}

}

/**/
- (int) getTextLength
{
			switch (myCurrentPosition) {
				case 1: return strlen([myTextBlok1 getText]);
				case 2: return strlen([myTextBlok2 getText]);
				case 3: return strlen([myTextBlok3 getText]);
				case 4: return strlen([myTextBlok4 getText]);
				case 5: return strlen([myTextBlok5 getText]);
				case 6: return strlen([myTextBlok6 getText]);
				case 7: return strlen([myTextBlok7 getText]);
				case 8: return strlen([myTextBlok8 getText]);
				case 9: return strlen([myTextBlok9 getText]);
				case 10: return strlen([myTextBlok10 getText]);
				case 11: return strlen([myTextBlok11 getText]);
				case 12: return strlen([myTextBlok12 getText]);
				case 13: return strlen([myTextBlok13 getText]);
		  }
			return 0;
}

/**/
- (BOOL) validateCode: (char*) aText
{
  char *p = aText;
	int pos;
	BOOL isOk;
	int count;

	pos = 0;
	count = 0;
	isOk = TRUE;

	while ((*p != '\0') && (isOk)) {
		pos++;
		if (pos == 4){
			// debe ser un espacio en blanco
			pos = 0;
		  isOk = (*p == ' ');
		}else{
			count++;
			// debe ser un numero de 0 a 9
			isOk = ((*p == '0') || (*p == '1') || (*p == '2') || (*p == '3') || (*p == '4') || (*p == '5') || (*p == '6') || (*p == '7') || (*p == '8') || (*p == '9'));
		}
		p++;
	}

	// debe haber 138 digitos como minimo (entre 0..9) sin contar los espacios en blanco
	isOk = (count >= 138);

	return isOk;

}

/**/
- (void) setCommercialState: (id) aValue
{
	myCommercialState = aValue;
}

/**/
- (void) generateReport
{
	scew_tree *tree;
	  	
	tree = [[ReportXMLConstructor getInstance] buildXML: myCommercialState entityType: CIM_COMMERCIAL_STATE_PRT isReprint: FALSE];
	[[PrinterSpooler getInstance] addPrintingJob: CIM_COMMERCIAL_STATE_PRT 
		copiesQty: 1
		ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
}

@end