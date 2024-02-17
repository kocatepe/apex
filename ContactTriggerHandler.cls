public with sharing class ContactTriggerHandler {
    static Map<Id, Integer> accSamplerCountMap = new Map<Id, Integer>();
    //static Map<Id, Account> accMap = new Map<Id, Account>();

    public static void handleSamplers(List<Contact> trgNew, List<Contact> trgOld, Map<Id,Contact> trgNewMap, Map<Id,Contact> trgOldMap){
        //Initialize accSamplerCountMap:
        List<Account> allAccsWithSamplers = [SELECT Id, Assigned_Samplers_Count__c FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Sampler__c = true)];
        for(Account acc : allAccsWithSamplers){
            accSamplerCountMap.put(acc.Id, acc.Assigned_Samplers_Count__c);
        }

        if(Trigger.isInsert || Trigger.isUndelete){
            List<Contact> consToValidate = new List<Contact>();
            for(Contact con : trgNew){
                if(con.Sampler__c && con.AccountId != null){
                    validateSampler(con);
                }
            }
        }

        if (Trigger.isUpdate) {
            //Set<Id> accIds = new Set<Id>();
            List<Contact> consToValidate = new List<Contact>();
            for (Contact con : trgNew) {
                /*
                if(con.Sampler__c && trgOldMap.get(con.Id).Sampler__c){
                    //If there's reparenting of a sampler:
                    if(con.accountId != trgOldMap.get(con.Id).AccountId){
                        if(trgOldMap.get(con.Id).AccountId != null){
                            //Decrement sampler count of the old parent:
                            accSamplerCountMap.put(trgOldMap.get(con.Id).AccountId, accSamplerCountMap.get(trgOldMap.get(con.Id).AccountId)-1);
                        }
                        if(con.accountId != null){
                            validateSampler(con);
                        }
                    }
                }
                else if(Change on Sampler__c and new = true && old = false)
                else if(Change on Sampler__c and new = false && old = true)
                */
                //Always re-calculate when the checkbox is updated
                if(con.Sampler__c != trgOldMap.get(con.Id).Sampler__c){
                    //accIds.add(con.AccountId);
                    //accIds.add(trgOldMap.get(con.Id).AccountId);
                    //Only validate if the new value of checkbox is true
                    if(con.Sampler__c){
                        if(validateSampler(con)){
                            //Decrement sampler count of the old parent:
                            accSamplerCountMap.put(trgOldMap.get(con.Id).AccountId, accSamplerCountMap.get(trgOldMap.get(con.Id).AccountId)-1);
                        }
                    }
                }
            }

            /*accMap.putAll(new Map<Id, Account>([SELECT Id, Size__c, Assigned_Samplers_Count__c FROM Account WHERE Id IN :accIds]));
            for(Account acc : accMap.values()){
                accSamplerCountMap.put(acc.Id, acc.Assigned_Samplers_Count__c);
            }
            if(!consToValidate.isEmpty()){
                for(Contact con : consToValidate){
                    if(validateSampler(con)){
                        accMap.remove(con.AccountId);
                        accMap.remove(trgOldMap.get(con.Id).AccountId);
                        con.Sampler__c.addError('The parent account has reached its max number of samplers.');
                    }
                }
            }*/
        }

        if(Trigger.isDelete){
            //No need for validation when deleting a Contact
            for(Contact con : trgOld){
                if(con.Sampler__c && con.AccountId != null){
                    accSamplerCountMap.put(con.AccountId, accSamplerCountMap.get(con.AccountId)-1);
                }
            }
        }

        if(!accSamplerCountMap.isEmpty()){
            List<Account> updAccs = [SELECT Id, Assigned_Samplers_Count__c, FROM Account WHERE Id IN :accSamplerCountMap.keySet()];
            for(Account acc : updAccs){
                acc.Assigned_Samplers_Count__c = accSamplerCountMap.get(acc.Id);
            }
            update updAccs;
        }
    }

    static Boolean validateSampler(Contact con){
        Boolean ok = true;
        Integer countNow = accSamplerCountMap.get(con.AccountId);
        if(countNow == null){
            countNow = 0;
        }
        if((accMap.get(con.AccountId).Size__c == 'Small' && countNow >= 1)
            || (accMap.get(con.AccountId).Size__c == 'Medium' && countNow >= 3)
            || (accMap.get(con.AccountId).Size__c == 'Large' && countNow >= 5)){
            ok = false;
            con.Sampler__c.addError('The parent account has reached its max number of samplers.');
        } else {
            countNow++;
            accSamplerCountMap.put(con.AccountId, countNow);
        }
        return ok;
    }

    /*static Boolean validateSampler(Contact con){
        Boolean error = false;
        Integer countNow = accSamplerCountMap.get(con.AccountId);
        if(countNow == null){
            countNow = 0;
        }
        if((accMap.get(con.AccountId).Size__c == 'Small' && countNow >= 1)
            || (accMap.get(con.AccountId).Size__c == 'Medium' && countNow >= 3)
            || (accMap.get(con.AccountId).Size__c == 'Large' && countNow >= 5)){
            error=true;
        } else {
            countNow++;
            accSamplerCountMap.put(con.AccountId, countNow);
        }
        return error;
    }*/
}
