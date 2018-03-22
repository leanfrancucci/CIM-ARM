#ifndef BOX_MODEL_H
#define BOX_MODEL_H

#define BOX_MODEL id

#include <Object.h>
#include "system/util/all.h"

/**
 *	Especifica el tipo fisico de caja.
 */
typedef enum {
	PhisicalModel_Box2ED2V1M,
	PhisicalModel_Box2ED1V1M,
	PhisicalModel_Box2EDI2V1M,
	PhisicalModel_Box2EDI1V1M,
	PhisicalModel_Box1ED2V1M,
	PhisicalModel_Box1ED1V1M,
	PhisicalModel_Box1ED1M,
	PhisicalModel_Box1D2V1M,
	PhisicalModel_Box1D1V1M,
	PhisicalModel_Box1D1M
	PhisicalModel_Flex
} PhisicalModel;

/**
 *	Especifica el tipo fisico de caja.
 */
typedef enum {
	ValidatorModel_JCM_PUB11_BAG,
	ValidatorModel_JCM_WBA_Stacker,
	ValidatorModel_JCM_BNF_Stacker,
	ValidatorModel_JCM_BNF_BAG,
	ValidatorModel_CC_CS_Stacker,
	ValidatorModel_CC_CCB_BAG,
	ValidatorModel_MEI_S66_Stacker
} ValidatorModel;

/**
 */
@interface BoxModel : Object
{
	PhisicalModel myPhisicalModel;
	ValidatorModel myVal1Model;
	ValidatorModel myVal2Model;
}

/**/
- (void) setPhisicalModel: (PhisicalModel) aValue;

/**/
- (void) setVal1Model: (ValidatorModel) aValue;

/**/
- (void) setVal2Model: (ValidatorModel) aValue;

/**/
- (void) save;

@end

#endif
