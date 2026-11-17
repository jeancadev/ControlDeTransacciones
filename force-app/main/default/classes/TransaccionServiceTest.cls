@IsTest
private class TransaccionServiceTest {
    @IsTest
    static void depositoSumaAlSaldo() {
        Cuenta_Bancaria__c cuenta = TestDataFactory.crearCuenta(100.00);

        Test.startTest();
        insert TestDataFactory.nuevaTransaccion(
            cuenta.Id,
            TransaccionConstants.TIPO_DEPOSITO,
            25.00
        );
        Test.stopTest();

        Assert.areEqual(125.00, saldoActual(cuenta.Id));
    }

    @IsTest
    static void retiroValidoRestaDelSaldo() {
        Cuenta_Bancaria__c cuenta = TestDataFactory.crearCuenta(100.00);

        Test.startTest();
        insert TestDataFactory.nuevaTransaccion(
            cuenta.Id,
            TransaccionConstants.TIPO_RETIRO,
            40.00
        );
        Test.stopTest();

        Assert.areEqual(60.00, saldoActual(cuenta.Id));
    }

    @IsTest
    static void retiroQueExcedeSaldoSeRechaza() {
        Cuenta_Bancaria__c cuenta = TestDataFactory.crearCuenta(100.00);
        Transaccion__c retiro = TestDataFactory.nuevaTransaccion(
            cuenta.Id,
            TransaccionConstants.TIPO_RETIRO,
            150.00
        );

        Test.startTest();
        Database.SaveResult resultado = Database.insert(retiro, false);
        Test.stopTest();

        Assert.isFalse(resultado.isSuccess());
        Assert.areEqual(Label.Saldo_Insuficiente, resultado.getErrors()[0].getMessage());
        Assert.areEqual(100.00, saldoActual(cuenta.Id));
    }

    @IsTest
    static void cuentaBloqueadaRechazaTransacciones() {
        Cuenta_Bancaria__c cuenta = TestDataFactory.crearCuenta(100.00);
        cuenta.Estado__c = TransaccionConstants.ESTADO_BLOQUEADA;
        update cuenta;

        Test.startTest();
        Database.SaveResult resultado = Database.insert(
            TestDataFactory.nuevaTransaccion(
                cuenta.Id,
                TransaccionConstants.TIPO_DEPOSITO,
                10.00
            ),
            false
        );
        Test.stopTest();

        Assert.isFalse(resultado.isSuccess());
        Assert.areEqual(Label.Cuenta_Bloqueada, resultado.getErrors()[0].getMessage());
        Assert.areEqual(100.00, saldoActual(cuenta.Id));
    }

    @IsTest
    static void dosRetirosEnMismoLoteProyectanElSaldo() {
        Cuenta_Bancaria__c cuenta = TestDataFactory.crearCuenta(100.00);
        List<Transaccion__c> retiros = new List<Transaccion__c>{
            TestDataFactory.nuevaTransaccion(
                cuenta.Id,
                TransaccionConstants.TIPO_RETIRO,
                60.00
            ),
            TestDataFactory.nuevaTransaccion(
                cuenta.Id,
                TransaccionConstants.TIPO_RETIRO,
                60.00
            )
        };

        Test.startTest();
        Database.SaveResult[] resultados = Database.insert(retiros, false);
        Test.stopTest();

        Assert.isTrue(resultados[0].isSuccess());
        Assert.isFalse(resultados[1].isSuccess());
        Assert.areEqual(Label.Saldo_Insuficiente, resultados[1].getErrors()[0].getMessage());
        Assert.areEqual(40.00, saldoActual(cuenta.Id));
    }

    @IsTest
    static void loteDeDoscientosDepositosActualizaElSaldoCorrectamente() {
        Cuenta_Bancaria__c cuenta = TestDataFactory.crearCuenta(0.00);
        List<Transaccion__c> depositos = new List<Transaccion__c>();
        for (Integer indice = 0; indice < 200; indice++) {
            depositos.add(TestDataFactory.nuevaTransaccion(
                cuenta.Id,
                TransaccionConstants.TIPO_DEPOSITO,
                1.00
            ));
        }

        Test.startTest();
        Database.SaveResult[] resultados = Database.insert(depositos, false);
        Test.stopTest();

        for (Database.SaveResult resultado : resultados) {
            Assert.isTrue(resultado.isSuccess(), 'Cada depósito del lote debe guardarse.');
        }
        Assert.areEqual(200.00, saldoActual(cuenta.Id));
    }

    @IsTest
    static void updateYDeleteDeTransaccionFallan() {
        Cuenta_Bancaria__c cuenta = TestDataFactory.crearCuenta(100.00);
        Transaccion__c transaccion = TestDataFactory.nuevaTransaccion(
            cuenta.Id,
            TransaccionConstants.TIPO_DEPOSITO,
            10.00
        );
        insert transaccion;

        transaccion.Monto__c = 99.00;
        Test.startTest();
        Database.SaveResult resultadoUpdate = Database.update(transaccion, false);
        Database.DeleteResult resultadoDelete = Database.delete(transaccion, false);
        Test.stopTest();

        Assert.isFalse(resultadoUpdate.isSuccess());
        Assert.areEqual(Label.Transaccion_Inmutable, resultadoUpdate.getErrors()[0].getMessage());
        Assert.isFalse(resultadoDelete.isSuccess());
        Assert.areEqual(Label.Transaccion_Inmutable, resultadoDelete.getErrors()[0].getMessage());
        Assert.areEqual(110.00, saldoActual(cuenta.Id));
        Transaccion__c transaccionPersistida = [
            SELECT Monto__c
            FROM Transaccion__c
            WHERE Id = :transaccion.Id
        ];
        Assert.areEqual(10.00, transaccionPersistida.Monto__c);
    }

    @IsTest
    static void montoNoPositivoSeRechazaPorValidationRule() {
        Cuenta_Bancaria__c cuenta = TestDataFactory.crearCuenta(100.00);

        Test.startTest();
        Database.SaveResult resultado = Database.insert(
            TestDataFactory.nuevaTransaccion(
                cuenta.Id,
                TransaccionConstants.TIPO_DEPOSITO,
                0.00
            ),
            false
        );
        Test.stopTest();

        Assert.isFalse(resultado.isSuccess());
        Assert.areEqual(Label.Monto_Debe_Ser_Mayor_A_Cero, resultado.getErrors()[0].getMessage());
        Assert.areEqual(100.00, saldoActual(cuenta.Id));
    }

    private static Decimal saldoActual(Id cuentaId) {
        return [SELECT Saldo__c FROM Cuenta_Bancaria__c WHERE Id = :cuentaId].Saldo__c;
    }
}
