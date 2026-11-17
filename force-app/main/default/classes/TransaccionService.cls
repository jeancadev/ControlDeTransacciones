public with sharing class TransaccionService {
    public static void validar(List<Transaccion__c> transacciones) {
        Map<Id, Cuenta_Bancaria__c> cuentas = CuentaSelector.porIdConBloqueo(
            idsDeCuentas(transacciones)
        );
        Map<Id, Decimal> saldoProyectado = new Map<Id, Decimal>();

        for (Transaccion__c tx : transacciones) {
            if (tx.Cuenta__c == null || tx.Monto__c == null || tx.Monto__c <= 0) {
                // La obligatoriedad y el monto positivo se validan declarativamente.
                continue;
            }

            Cuenta_Bancaria__c cuenta = cuentas.get(tx.Cuenta__c);
            if (cuenta == null) {
                continue;
            }

            if (cuenta.Estado__c == TransaccionConstants.ESTADO_BLOQUEADA) {
                tx.addError(Label.Cuenta_Bloqueada);
                continue;
            }

            Decimal saldo = saldoProyectado.containsKey(cuenta.Id)
                ? saldoProyectado.get(cuenta.Id)
                : cuenta.Saldo__c;

            if (tx.Tipo__c == TransaccionConstants.TIPO_RETIRO && tx.Monto__c > saldo) {
                tx.addError(Label.Saldo_Insuficiente);
                continue;
            }

            saldoProyectado.put(cuenta.Id, saldo + efectoEnSaldo(tx));
        }
    }

    public static void aplicarASaldo(List<Transaccion__c> transacciones) {
        Map<Id, Cuenta_Bancaria__c> cuentas = CuentaSelector.porId(
            idsDeCuentas(transacciones)
        );

        for (Transaccion__c tx : transacciones) {
            Cuenta_Bancaria__c cuenta = cuentas.get(tx.Cuenta__c);
            if (cuenta != null) {
                cuenta.Saldo__c += efectoEnSaldo(tx);
            }
        }

        if (!cuentas.isEmpty()) {
            update cuentas.values();
        }
    }

    public static void rechazarModificacion(List<Transaccion__c> transacciones) {
        for (Transaccion__c tx : transacciones) {
            tx.addError(Label.Transaccion_Inmutable);
        }
    }

    private static Decimal efectoEnSaldo(Transaccion__c tx) {
        return tx.Tipo__c == TransaccionConstants.TIPO_RETIRO ? -tx.Monto__c : tx.Monto__c;
    }

    private static Set<Id> idsDeCuentas(List<Transaccion__c> transacciones) {
        Set<Id> ids = new Set<Id>();
        for (Transaccion__c tx : transacciones) {
            if (tx.Cuenta__c != null) {
                ids.add(tx.Cuenta__c);
            }
        }
        return ids;
    }
}
