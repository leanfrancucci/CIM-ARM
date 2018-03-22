#include <stdio.h>
#include <ctype.h>

#include "ASCIIFormatterWriter.h"

/**/
@implementation ASCIIFormatterWriter

/**/ 
- initWithWriter: (WRITER) aWriter
{
	myIndex = 0;
	
	return [super initWithWriter: aWriter];
}

/**/
- (int) write: (char *) aBuf qty: (int) aQty
{
	char *p;
		
	THROW_NULL(myWriter);	

	/* ineficiente */
	memset(myBuffer, '\0', sizeof(myBuffer));
	
	/**/
	if (aQty <= 0 )	{
		sprintf(myBuffer, "%d: %s\n", myIndex++, "--");
		[myWriter write: myBuffer qty: strlen(myBuffer)];
		return 0;
	}
	
	/**/
	sprintf(myBuffer, "%d: ", myIndex++);
	p = myBuffer + strlen(myBuffer);
	while (aQty--) {
		
		/**/
		if (*aBuf < 32) {
			
			if (*aBuf == '\n') {
				*p++ = '\\';
				*p++ = 'n';
			} else {
				sprintf(p, "\\" "%c", *aBuf + '0');
				p += 3;
			}
		
		} else 
			*p++ = *aBuf;
		
		/* pasa al otro caracter */
		aBuf++;	
		
		/* si se pasa sale escribiendo "..." */
		if (p - myBuffer >= sizeof(myBuffer) - 5) {
			strcat(myBuffer, "...");
			break;
		}			
	}

		
	strcat(myBuffer, "\n");	
	[myWriter write: myBuffer qty: strlen(myBuffer)];
	
	return p - myBuffer;
}

@end

