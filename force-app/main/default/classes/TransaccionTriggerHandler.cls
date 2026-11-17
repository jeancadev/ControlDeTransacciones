public with sharing class TransaccionTriggerHandler {
    public static void run() {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                TransaccionService.validar((List<Transaccion__c>) Trigger.new);
            }
            when AFTER_INSERT {
                TransaccionService.aplicarASaldo((List<Transaccion__c>) Trigger.new);
            }
            when BEFORE_UPDATE {
                TransaccionService.rechazarModificacion((List<Transaccion__c>) Trigger.new);
            }
            when BEFORE_DELETE {
                TransaccionService.rechazarModificacion((List<Transaccion__c>) Trigger.old);
            }
        }
    }
}
