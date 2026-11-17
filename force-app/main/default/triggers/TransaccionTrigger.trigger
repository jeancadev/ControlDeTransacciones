trigger TransaccionTrigger on Transaccion__c (
    before insert, after insert, before update, before delete
) {
    TransaccionTriggerHandler.run();
}
