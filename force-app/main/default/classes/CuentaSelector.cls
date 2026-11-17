public with sharing class CuentaSelector {
    public static Map<Id, Cuenta_Bancaria__c> porId(Set<Id> ids) {
        return new Map<Id, Cuenta_Bancaria__c>([
            SELECT Id, Saldo__c, Estado__c
            FROM Cuenta_Bancaria__c
            WHERE Id IN :ids
        ]);
    }

    // Mantiene el bloqueo hasta que termine la transacción actual.
    public static Map<Id, Cuenta_Bancaria__c> porIdConBloqueo(Set<Id> ids) {
        return new Map<Id, Cuenta_Bancaria__c>([
            SELECT Id, Saldo__c, Estado__c
            FROM Cuenta_Bancaria__c
            WHERE Id IN :ids
            FOR UPDATE
        ]);
    }
}
