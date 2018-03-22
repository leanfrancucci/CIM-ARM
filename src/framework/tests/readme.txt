** Deposit **
	Probar agregando distintos tipos de valores y verificando que el total y cantidad sean correctos
	y que esten bien ordenados.
	Probar rechazando billetes para ver si los incremente correctamente.

** DepositDetail **
	Metodos get/set.

** BillAcceptor **
	Probar ingresando a mano billetes.

** AbstractAcceptor **

** Cim **

** CimManager **

METODOS
//////////////////////////////////////////////////////////////////////////////////////

	- startDeposit() -> Comienza un timer de inactividad que se resetea con cada billete
	- endDeposit() -> Finaliza el timer de inactividad y guarda el deposito.
	- startExtraction()
	- endExtraction()

EVENTOS
//////////////////////////////////////////////////////////////////////////////////////
	- onDoorOpen() -> si estoy haciendo en una puerta de extraccion, 
			cierro el deposito actual y luego llamo a startExtraction() / endExtraction()
	- onDoorClose() -> audito el cierre de la puerta.
	- onBillAccepted() -> Si estoy en deposito acumulo el billete. Si estoy en Idle emito un sonido.
	- onBillRejected() -> Si estoy en deposito, acumulo el rechazo. Si estoy en Idle emito un sonido.
	- onManualDrop() ->

** Door **

** CimStateDeposit **

** CimStateIdle **

** Denomination **
	Metodos get/set.

** AcceptedCurrency **
	Metodos get/set.

** Currency **
	Metodos get/set.

** AcceptedValueType **
	Metodos get/set.

*************** 1. Deposito manual ***************
- Realizar diversos depositos con distintos tipos de valores 
	Probar la cantidad maxima de valores que se pueden ingresar.

	* Comienza con CimManager.startDeposit()
	* Se ingresan con CimManager.onManualDrop() ???
	* Se finaliza el deposito con CimManager.endDeposit()

************* 2. Deposito automatico ************************************
- Realizar diversos depositos configurados de diferentes maneras, aceptando
	algunos billetes y rechazando otros.
	* Comienza con CimManager.startDeposit()
	* Se ingresan billetes con _billAccepted() y _billRejected()
	* Se finaliza el deposito con CimManager.endDeposit()

************* 3. Extraccion *********************************************
- Limpiar la base de datos
- Realizar varios depositos
- Realizar una extraccion
- Comprobar que el resultado de los depositos sea correcto

Realizar una extraccion mientras se realiza un deposito.

