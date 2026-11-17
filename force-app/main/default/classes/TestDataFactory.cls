@IsTest
public class TestDataFactory {
    public static Cuenta_Bancaria__c crearCuenta(Decimal saldo) {
        Cuenta_Bancaria__c cuenta = new Cuenta_Bancaria__c(
            Saldo__c = saldo,
            Estado__c = TransaccionConstants.ESTADO_ACTIVA
        );
        insert cuenta;
        return cuenta;
    }

    public static Transaccion__c nuevaTransaccion(Id cuentaId, String tipo, Decimal monto) {
        return new Transaccion__c(Cuenta__c = cuentaId, Tipo__c = tipo, Monto__c = monto);
    }
}
