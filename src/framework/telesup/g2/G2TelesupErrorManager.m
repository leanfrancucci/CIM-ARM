#include "system/util/all.h"
#include "TelesupExcepts.h"
#include "G2TelesupErrorManager.h"

//#define printd(args...) 	doLog(0,args)
#define printd(args...) 	

struct G2TSErrCodes
{
	int		excode;
	int		tscode;	
};


static struct G2TSErrCodes errcodes[] =
{	
	 { TSUP_GENERAL_EX, 					1	}
	,{ TSUP_INVALID_REQUEST_EX, 			2	}
	,{ TSUP_PARAM_NOT_FOUND_EX,  			3	}
	,{ TSUP_INVALID_DATETIME_VAL_EX,  		4	}
	/* La entidad esta inactiva */
	,{ INVALID_REFERENCE_EX, 				5	}
	/* La entidad no existe */
	,{ REFERENCE_NOT_FOUND_EX,  			6	}		
	/* La entidad esta inactiva */
	,{ INVALID_PARAM_EX,					7	}
	,{ DAO_DUPLICATED_REFERENCE_EX,			8	}
	,{ DAO_NULLED_VALUE_EX,					9	}
	,{ DAO_OUT_OF_RANGE_VALUE_EX,			10	}
	,{ DAO_ENTITY_ALREADY_ACTIVATED_EX,		11	}
	,{ DAO_ENTITY_ALREADY_DEACTIVATED_EX,	12	}
	,{ TSUP_FILE_NOT_FOUND_EX,				13	}
	,{ FT_FILE_TRANSFER_ERROR,				14	}
	/* El mensaje no puede ser recibido dentro del contexto de un Job */
	,{ TS_INVALID_JOB_REQUEST_EX,			15	}
	,{ TS_JOB_RUNNING_EX,					16	}
	,{ TS_JOB_NOT_RUNNING_EX,				17	}
	,{ TSUP_INVALID_FILTER_EX,				18	}	
	,{ TSUP_KEY_NOT_FOUND,					19	}
};


/**/
@implementation G2TelesupErrorManager

/**/
+ new
{
	return [[super new] initialize];

}

/**/
- free
{
	return self;
}

/**/
- initialize
{
	[super initialize];
	
	return self;
}
	
/**/
- (int) getErrorCode: (int) excode
{
	static struct G2TSErrCodes *p;
	
	//doLog(0,"G2TelesupErrorManager -> getErrorCode = %d\n", excode);

	for (p = &errcodes[0]; p < &errcodes[sizeof(errcodes) / sizeof(errcodes[0])]; p++)
		if(p->excode == excode)
				return p->tscode;
	
	//doLog(0,"G2TelesupErrorManager -> error general desconocido\n");
	/* Error general desconocido */
	return excode;
}


@end
