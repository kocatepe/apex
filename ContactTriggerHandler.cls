public with sharing class ContactTriggerHandler {
    static Map<Id, Account> accMap = new Map<Id, Account>();

    public static void handleSamplers(List<Contact> trgNew, List<Contact> trgOld, Map<Id,Contact> trgNewMap, Map<Id,Contact> trgOldMap){

        if(Trigger.isInsert || Trigger.isUndelete){
            Set<Id> accIds = new Set<Id>();
            List<Contact> consToValidate = new List<Contact>();
            for(Contact con : trgNew){
                if(con.Sampler__c && con.AccountId != null){
                    consToValidate.add(con);
                    accIds.add(con.AccountId);
                }
            }

            accMap.putAll(new Map<Id, Account>([SELECT Id, Size__c, Assigned_Samplers_Count__c FROM Account WHERE Id IN :accIds]));

            if(!consToValidate.isEmpty()){
                for(Contact con : consToValidate){
                    if(validateSampler(con)){
                        accMap.remove(con.AccountId);
                        con.Sampler__c.addError('The parent account has reached its max number of samplers.');
                    }
                }
            }
        }

        if (Trigger.isUpdate) {
            Set<Id> accIds = new Set<Id>();
            List<Contact> consToValidate = new List<Contact>();
            for (Contact con : trgNew) {
                //Always re-calculate when the checkbox is updated
                if(con.Sampler__c != trgOldMap.get(con.Id).Sampler__c){
                    accIds.add(con.AccountId);
                    accIds.add(trgOldMap.get(con.Id).AccountId);
                    //Only validate if the new value of checkbox is true
                    if(con.Sampler__c){
                        consToValidate.add(con);
                    }
                //Reparenting of a sampler:
                } else if(con.Sampler__c && con.accountId != trgOldMap.get(con.Id).AccountId){
                    //Re-calculate the old parent
                    accIds.add(trgOldMap.get(con.Id).AccountId);
                    if(con.accountId != null){
                        //Validate and re-calculate the new parent
                        consToValidate.add(con);
                        accIds.add(con.AccountId);
                    }
                }
            }

            accMap.putAll(new Map<Id, Account>([SELECT Id, Size__c, Assigned_Samplers_Count__c FROM Account WHERE Id IN :accIds]));

            if(!consToValidate.isEmpty()){
                for(Contact con : consToValidate){
                    if(validateSampler(con)){
                        accMap.remove(con.AccountId);
                        accMap.remove(trgOldMap.get(con.Id).AccountId);
                        con.Sampler__c.addError('The parent account has reached its max number of samplers.');
                    }
                }
            }
        }

        if(Trigger.isDelete){
            Set<Id> accIds = new Set<Id>();
            //No need for validation when deleting a Contact
            for(Contact con : trgOld){
                if(con.Sampler__c && con.AccountId != null){
                    accIds.add(con.AccountId);
                }
            }
            accMap.putAll(new Map<Id, Account>([SELECT Id, Size__c, Assigned_Samplers_Count__c FROM Account WHERE Id IN :accIds]));
        }

        if(!accMap.isEmpty()){
            List<Account> updAccs = [SELECT Id, Assigned_Samplers_Count__c,
                                    (SELECT Id FROM Contacts WHERE Sampler__c = TRUE)
                                    FROM Account WHERE Id IN :accMap.keySet()];
            for(Account acc : updAccs){
                acc.Assigned_Samplers_Count__c = acc.Contacts.size();
            }
            update updAccs;
        }
    }

    static Boolean validateSampler(Contact con){
        Boolean error = false;
        switch on accMap.get(con.AccountId).Size__c {
            when 'Small' {if(accMap.get(con.AccountId).Assigned_Samplers_Count__c >= 1) error=true;}
            when 'Medium' {if(accMap.get(con.AccountId).Assigned_Samplers_Count__c >= 3) error=true;}
            when 'Large' {if(accMap.get(con.AccountId).Assigned_Samplers_Count__c >= 5) error=true;}
        }
        return error;
    }
}