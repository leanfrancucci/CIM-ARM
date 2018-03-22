/** 
 *	@mainpage
 *	Documentacion general de CIM (Caja de seguridad multideposito)
 *
 *  A continuacion se describen las clases mas importantes del paquete.
 *  
 *	@ref Deposit Contiene la informacion propia de un deposito.
 *	
 *  @ref DepositDetail Informacion del detalle de un deposito (un deposito contiene varios detalles)
 *  
 *  @ref Extraction Contiene la informacion propia de una extraccion.
 *
 *	@ref ExtractionDetail Informacion del detalle de una extraccion (una extraccion contiene varios detalles)
 *  
 *  @ref CimManager Clase principal que recibe todos los eventos de los dispositivos (validadores, sensores de puerta, etc) y los
 *	distribuye a la clase apropiada. Tiene un estado actual (a traves de un patron State) definido en la clase @ref CimState
 * 	dependiendo si esta en un deposito, una extraccion o idle.
 *
 *	@ref CimState Clase padre del estado actual del CIM. Es abstracta.
 *
 *	@ref CimStateIdle Se activa cuando el CIM esta ocioso.
 *
 *	@ref CimStateDeposit Se activa cuando se esta realizando un deposito.
 *
 *	@ref CimStateExtraction Se activa cuando se esta realizando una extraccion.
 *  
 *  @ref Door Representa una puerta. Tiene asociados los dispositivos "aceptadores" para esa puerta.
 *
 *	@ref AbstractAcceptor Representa un dispositivo "aceptador". Luego tendra subclases dependiendo de si se trata de un validador
 *	(@ref BillAcceptor) o un buzon (@ref EnvelopeAcceptor).
 *
 *	@ref ExtractionManager Clase que maneja los valores actuales de caja y genera la extraccion.
 *
 *  @ref CimDefs.h Declaraciones y estructuras comunes a todo el subsistema de CIM.
 *  
 *  @ref CimExcepts.h Excepciones posibles que pueden producirse.
 *  
 *  <b>Diagrama de clases</b>
 *  @image html clases.jpg
 *
 *  <b>Diagrama de secuencia</b>  
 *  @image html sentMessage.jpg
 *  
 *  <b>Diagrama de secuenciae</b>
 *  @image html receiveMessage.jpg
 */
