#ifndef EVENT_CATEGORY_H
#define EVENT_CATEGORY_H

#define EVENT_CATEGORY id

#include "Object.h"
#include "ctapp.h"

/**
 *	Especifica el tipo de categoria de eventos.
 */
typedef enum {
	EventCategoryType_UNDEFINED,
	EventCategoryType_GENERAL_EVENTS,	   /* Categoria: Eventos Generales */
	EventCategoryType_TARIFF_EVENTS,	   /* Categoria: Eventos de Tarifacion */
	EventCategoryType_BILL_EVENTS,	     /* Categoria: Eventos de Facturacion */
	EventCategoryType_SETTINGS,		       /* Categoria: Configuracion */
	EventCategoryType_TECHNICAL_SUPPORT, /* Categoria: Eventos de Soporte tecnico */
	EventCategoryType_VIEWER_EVENTS,     /* Categoria: Eventos de Visor */
  EventCategoryType_SUPERVITION,		   /* Categoria: Supervicion */
  EventCategoryType_PC_CONTROL_EVENTS, /* Categoria: Eventos de Control de PC */
	EventCategoryType_SECURITY,		       /* Categoria: Seguridad */
	EventCategoryType_ALARMS,		         /* Categoria: Alarmas */
	EventCategoryType_DOORS,		         /* Categoria: Puertas */
	EventCategoryType_CASH,		           /* Categoria: Valores */
	EventCategoryType_REPORTS		         /* Categoria: Reportes */
} EventCategoryType;

/**
 *	Representa una categoria de eventos.
 * 	
 */
@interface EventCategory :  Object
{
	int myEventCategoryId;
	char myDescription[30];
	BOOL myLogCategory;
	BOOL myDeleted;
	char myResource[11];
}

/**
 * Setea los valores correspondientes a la categoria de eventos
 */

- (void) setEventCategoryId: (int) aValue;
- (void) setCatEventDescription: (char*) aValue;
- (void) setLogEventCategory: (BOOL) aValue; 
- (void) setDeleted: (BOOL) aValue;
- (void) setResource: (char*) aValue;

/**
 * Devuelve los valores correspondientes a la categoria de eventos
 */

- (int) getEventCategoryId;
- (char*) getCatEventDescription;
- (BOOL) logEventCategory;
- (BOOL) isDeleted;
- (char*) getResource;
	
/**
 * Aplica los cambios realizados a la categoria de eventos en la persistencia.
 */

- (void) applyChanges;

/**
 * Restaura los valores de la persistencia
 */

- (void) restore;

@end

#endif


