public with sharing class ContactTriggerHandler {
    static Map<Id, String> accSizeSamplerCountMap = new Map<Id, String>();

    public static void handleSamplers(List<Contact> trgNew, List<Contact> trgOld, Map<Id,Contact> trgNewMap, Map<Id,Contact> trgOldMap){
        //Initialize accSizeSamplerCountMap:
        List<Account> allAccsWithSamplers = [SELECT Id, Size__c, Assigned_Samplers_Count__c FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Sampler__c = true)];
        for(Account acc : allAccsWithSamplers){
            String sizeAndCount = acc.Size__c + '-' + acc.Assigned_Samplers_Count__c;
            //Example sizeAndCount: 'Medium-2'
            accSizeSamplerCountMap.put(acc.Id, sizeAndCount);
        }

        if(Trigger.isInsert || Trigger.isUndelete){
            for(Contact con : trgNew){
                if(con.Sampler__c && con.AccountId != null && validateSampler(con)){
                    incrementCount(con.accountId);
                }
            }
        }

        if (Trigger.isUpdate) {
            for (Contact con : trgNew) {

            }
/*
1. if(con.Sampler__c && trgOldMap.get(con.Id).Sampler__c && (con.accountId != trgOldMap.get(con.Id).AccountId))
    //If there's reparenting of a sampler:
    1.1. if(con.accountId != null && validateSampler(con))
            incrementCount(con.accountId);
            if(trgOldMap.get(con.Id).AccountId != null)
                decrementCount(trgOldMap.get(con.Id).AccountId);
    1.2.

old-1.1. if(trgOldMap.get(con.Id).AccountId != null)
        //Decrement sampler count of the old parent:
        decrementCount(trgOldMap.get(con.Id).AccountId);
old-1.2. if(con.accountId != null)
        validateSampler(con);

2. else if(con.Sampler__c && !trgOldMap.get(con.Id).Sampler__c)
    validateSampler(con);

3. else if(!con.Sampler__c && trgOldMap.get(con.Id).Sampler__c)
    //Reparented and de-checked:
    3.1. if(con.accountId != trgOldMap.get(con.Id).AccountId)
        decrementCount(trgOldMap.get(con.Id).AccountId);
    3.2. else //Same parent, de-checked:
        decrementCount(con.AccountId);
*/
/*            for (Contact con : trgNew) {
                //Reparenting:
                if(con.accountId != trgOldMap.get(con.Id).AccountId){
                    if(con.Sampler__c && trgOldMap.get(con.Id).Sampler__c){
                        if(trgOldMap.get(con.Id).AccountId != null){
                            //Decrement sampler count of the old parent:
                            decrementCount(trgOldMap.get(con.Id).AccountId);
                        }
                        if(con.accountId != null){
                            validateSampler(con);
                        }
                    }
                } else { //No reparenting:

                }
 /*else if(con.Sampler__c && !trgOldMap.get(con.Id).Sampler__c) {
                    if(con.accountId != null){
                        validateSampler(con);
                    }
                } else if(!con.Sampler__c && trgOldMap.get(con.Id).Sampler__c) {

                }*/

                //Always re-calculate when the checkbox is updated
                if(con.Sampler__c != trgOldMap.get(con.Id).Sampler__c){
                    //accIds.add(con.AccountId);
                    //accIds.add(trgOldMap.get(con.Id).AccountId);
                    //Only validate if the new value of checkbox is true
                    if(con.Sampler__c){
                        if(validateSampler(con)){
                            //Decrement sampler count of the old parent:
                            decrementCount(trgOldMap.get(con.Id).AccountId);
                        }
                    }
                }
            }*/
        }

        if(Trigger.isDelete){
            //No need for validation when deleting a Contact
            for(Contact con : trgOld){
                if(con.Sampler__c && con.AccountId != null){
                    decrementCount(con.AccountId);
                }
            }
        }

        if(!accSizeSamplerCountMap.isEmpty()){
            List<Account> updAccs = [SELECT Id, Size__c, Assigned_Samplers_Count__c FROM Account WHERE Id IN :accSizeSamplerCountMap.keySet()];
            for(Account acc : updAccs){
                acc.Assigned_Samplers_Count__c = Integer.valueOf(accSizeSamplerCountMap.get(acc.Id).substringAfter('-'));
                if(acc.Size__c == null){
                    //Update the size of Account according to current sampler count:
                    if(acc.Assigned_Samplers_Count__c <= 1){
                        acc.Size__c = 'Small';
                    } else if(acc.Assigned_Samplers_Count__c <= 3){
                        acc.Size__c = 'Medium';
                    } else {
                        acc.Size__c = 'Large';
                    }
                }
            }
            update updAccs;
        }
    }

    static Boolean validateSampler(Contact con){
        Boolean ok = true;
        String accSize = accSizeSamplerCountMap.get(con.AccountId)?.substringBefore('-');
        Integer recentCount = Integer.valueOf(accSizeSamplerCountMap.get(con.AccountId)?.substringAfter('-') ?? '0');
        if((accSize == 'Small' && recentCount >= 1) || (accSize == 'Medium' && recentCount >= 3) || (accSize == 'Large' && recentCount >= 5)){
            ok = false;
            con.Sampler__c.addError('The parent account has reached its max number of samplers.');
        }
        return ok;
    }

    static void incrementCount(Id accId){
        String sizeAndCount = accSizeSamplerCountMap.get(accId);
		if(sizeAndCount != null){
            Integer currentCount = Integer.valueOf(sizeAndCount.substringAfter('-') ?? '0');
            currentCount++;
            sizeAndCount = sizeAndCount.substringBefore('-') + '-' + currentCount;
        } else {
            sizeAndCount = 'NOSIZE-1';
        }
        accSizeSamplerCountMap.put(accId, sizeAndCount);
    }

    static void decrementCount(Id accId){
        String sizeAndCount = accSizeSamplerCountMap.get(accId);
        Integer currentCount = Integer.valueOf(sizeAndCount.substringAfter('-') ?? '0');
        currentCount--;
        sizeAndCount = sizeAndCount.substringBefore('-') + '-' + currentCount;
        accSizeSamplerCountMap.put(accId, sizeAndCount);
    }
}
