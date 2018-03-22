#include "JSystemConfigForm.h"
#include "JMessageDialog.h"
#include "MessageHandler.h"
#include "CimGeneralSettings.h"

//#define printd(args...) doLog(args)
#define printd(args...)

#define ETH0_FILE_NAME BASE_PATH "/etc/interfaces/eth0"

@implementation  JSystemConfigForm

/*
dhcp: no
address: 192.168.0.177
netmask: 255.255.255.0
gateway: 192.168.0.1
*/

/**/
- (void) loadIPConfig
{
	char dhcp[10];
	char ipAddress[20];
	char netMask[20];
	char gateway[20];

	// levanto los valores
	//loadIPConfig(dhcp, ipAddress, netMask, gateway);

	[[CimGeneralSettings getInstance] getDhcp: dhcp];
	if (strcmp(dhcp, "no") == 0) [myComboDHCP setSelectedIndex: 0];
	else [myComboDHCP setSelectedIndex: 1];

	[[CimGeneralSettings getInstance] getIpAddress: ipAddress];
	[myTextIP setText: ipAddress];
	[[CimGeneralSettings getInstance] getNetMask: netMask];
	[myTextNetmask setText: netMask];
	[[CimGeneralSettings getInstance] getGateway: gateway];
	[myTextGateway setText: gateway];
}

/**/
- (void) saveIPConfig
{
	char dhcp[10];
	char ipAddress[20];
	char netMask[20];
	char gateway[20];
	FILE *f;

	// si no utiliza DHCP piso el archivo de configuracion con los nuevos valores.
	// En caso contrario mantengo los valores del archivo de confg. escepto el campo dhcp.
	if ([myComboDHCP getSelectedIndex] == 0) {
		strcpy(ipAddress, [myTextIP getText]);
		strcpy(netMask, [myTextNetmask getText]);
		strcpy(gateway, [myTextGateway getText]);
	} else {
		// levanto los valores del archivo
		loadIPConfigFromFile(dhcp, ipAddress, netMask, gateway);
	}

	// almaceno los valores en el archivo de configuracion
	f = fopen(ETH0_FILE_NAME, "w+");

	fprintf(f, "dhcp: %s\n", ([myComboDHCP getSelectedIndex] == 0) ? "no" : "yes");
	fprintf(f, "address: %s\n", ipAddress);
	fprintf(f, "netmask: %s\n", netMask);
	fprintf(f, "gateway: %s\n", gateway);
	fclose(f);

	// almaceno los nuevos valores en memoria
	[[CimGeneralSettings getInstance] setIpAddress: ipAddress];
	[[CimGeneralSettings getInstance] setNetMask: netMask];
	[[CimGeneralSettings getInstance] setGateway: gateway];

	if ([myComboDHCP getSelectedIndex] == 0)
		[[CimGeneralSettings getInstance] setDhcp: "no"];
	else
		[[CimGeneralSettings getInstance] setDhcp: "yes"];

}

/**
 * Si esta en modo VIEW entra en modo EDIT.
 * Si esta en modo EDIT, acepta el formulario y entra en modo VIEW
 */
- (void) onMenu2ButtonClick
{
	BOOL mustPaint;
	
	mustPaint = FALSE;
		
	[self lockWindowsUpdate];
	
	TRY

			/* Paso a modo edicion ... */
			if (myFormMode == JEditFormMode_VIEW && myIsEditable) {
			
				[self doChangeFormMode: JEditFormMode_EDIT];
				[self dhcp_onSelect];
				mustPaint = TRUE;
								
			} else { 	/* Valida, acepta y pasa a modo view */
			
				if (myFormMode == JEditFormMode_EDIT) {
 					if ([self doAcceptForm])
						[self doChangeFormMode: JEditFormMode_VIEW];
				}				
			}
		
	FINALLY
		
      [self unlockWindowsUpdate];
			[self sendPaintMessage];
		
	END_TRY;
}

/**/
- (void) onCreateForm
{
	[super onCreateForm];
	printd("JSystemConfigForm:onCreateForm\n");

	/* DHCP */
	myLabelDHCP = [JLabel new];
	[myLabelDHCP setCaption: "DHCP:"];
	[self addFormComponent: myLabelDHCP];
  [self addFormEol];
	
	myComboDHCP = [JCombo new];
	[myComboDHCP addString: getResourceStringDef(RESID_NO, "No")];
	[myComboDHCP addString: getResourceStringDef(RESID_YES, "Si")];
	[myComboDHCP setOnSelectAction: self action: "dhcp_onSelect"];
	[self addFormComponent: myComboDHCP];
  [self addFormNewPage];

	
	/* IP del equipo */
	myLabelIP = [JLabel new];
	[myLabelIP setCaption: getResourceStringDef(RESID_EQUIPMENT_IP, "IP del equipo:")];
	[self addFormComponent: myLabelIP];

	myTextIP = [JText new];
	[myTextIP setNumericMode: TRUE];
	[myTextIP setWidth: 16];
	[myTextIP setHeight: 1];
	[myTextIP setNumericType: JTextNumericType_IP];  
	[self addFormComponent: myTextIP];
  
  [self addFormNewPage];
  
	/* Mascara de subred */
	myLabelNetmask = [JLabel new];
	[myLabelNetmask setCaption: getResourceStringDef(RESID_NET_MASK, "Mascara de subred:")];
	[self addFormComponent: myLabelNetmask];

	myTextNetmask = [JText new];
	[myTextNetmask setNumericMode: TRUE];
	[myTextNetmask setWidth: 16];
	[myTextNetmask setHeight: 1];
	[myTextNetmask setNumericType: JTextNumericType_IP];    
  [self addFormComponent: myTextNetmask];
  
  [self addFormNewPage];
  
	/* Gateway */
	myLabelGateway = [JLabel new];
	[myLabelGateway setCaption: "Gateway:"];
	[self addFormComponent: myLabelGateway];

	myTextGateway = [JText new];
	[myTextGateway setNumericMode: TRUE];
	[myTextGateway setWidth: 16];
	[myTextGateway setHeight: 1];
	[myTextGateway setNumericType: JTextNumericType_IP];    
  [self addFormComponent: myTextGateway];  

	[self loadIPConfig];
 	[self setConfirmAcceptOperation: TRUE];
		 
}

/**/
- (void) onCancelForm: (id) anInstance
{
	[self loadIPConfig];
}

/**/
- (void) onModelToView: (id) anInstance
{
}

/**/
- (void) onViewToModel: (id) anInstance
{
}

/**/
- (void) onAcceptForm: (id) anInstance
{
	[self saveIPConfig];
  [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_RESTART_EQUIPMENT, "Para aplicar los cambios, reinicie el equipo.")];
}

/**/
- (void) dhcp_onSelect
{
	if ([myComboDHCP getSelectedIndex] == 0) {
		[myTextIP setReadOnly: FALSE];
		[myTextNetmask setReadOnly: FALSE];
		[myTextGateway setReadOnly: FALSE];
	} else {
		[myTextIP setReadOnly: TRUE];
		[myTextNetmask setReadOnly: TRUE];
		[myTextGateway setReadOnly: TRUE];
	}

	[self paintComponent];
}

@end

