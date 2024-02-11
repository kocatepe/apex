trigger ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    ContactTriggerHandler.handleSamplers(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
}