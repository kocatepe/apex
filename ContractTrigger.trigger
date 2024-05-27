trigger ContractTrigger on Contract (after insert, after update) {
    if(Trigger.isAfter && Trigger.isInsert){
        ERPCallouts.handleInsert(Trigger.newMap);
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        ERPCallouts.handleUpdate(Trigger.new, Trigger.oldMap);
    }
}