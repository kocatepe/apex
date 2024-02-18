public with sharing class ContactTriggerHandler {
    static Map<Id, String> accSizeSamplerCountMap = new Map<Id, String>();
    static {
        //Populate accSizeSamplerCountMap:
        List<Account> allAccsWithSamplers = [SELECT Id, Size__c, Assigned_Samplers_Count__c FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Sampler__c = true)];
        for(Account acc : allAccsWithSamplers){
            String size = acc.Size__c ?? 'NOSIZE';
            Integer count = Integer.valueOf(acc.Assigned_Samplers_Count__c) ?? 0;
            String sizeAndCount = size + '-' + count;
            //sizeAndCount examples: 'Medium-2', 'NOSIZE-7', 'Large-0'
            accSizeSamplerCountMap.put(acc.Id, sizeAndCount);
        }
    }

    public static void handleSamplers(List<Contact> trgNew, List<Contact> trgOld, Map<Id,Contact> trgNewMap, Map<Id,Contact> trgOldMap){
        if(Trigger.isBefore && Trigger.isDelete){
            //No need for validation when deleting a Contact
            for(Contact con : trgOld){
                if(con.Sampler__c && con.AccountId != null){
                    decrementCount(con.AccountId);
                }
            }
        }

        if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUndelete)){
            for(Contact con : trgNew){
                if(con.Sampler__c && con.AccountId != null && validateSampler(con)){
                    incrementCount(con.accountId);
                }
            }
        }

        if(Trigger.isAfter && Trigger.isUpdate) {
            for (Contact con : trgNew) {
                //If there's reparenting of a sampler:
                if(con.Sampler__c && trgOldMap.get(con.Id).Sampler__c && (con.accountId != trgOldMap.get(con.Id).AccountId)){
                    if(con.accountId != null){
                        if(validateSampler(con)){
                            incrementCount(con.accountId);
                            if(trgOldMap.get(con.Id).AccountId != null){
                                decrementCount(trgOldMap.get(con.Id).AccountId);
                            }
                        }
                    } else {
                        decrementCount(trgOldMap.get(con.Id).AccountId);
                    }
				} else if(con.Sampler__c && !trgOldMap.get(con.Id).Sampler__c) {
                    if(con.accountId != null){
                        if(validateSampler(con)){
                            incrementCount(con.accountId);
                        }
                    }
                } else if(!con.Sampler__c && trgOldMap.get(con.Id).Sampler__c) {
                    if((con.accountId == trgOldMap.get(con.Id).AccountId) && (con.accountId != null)){
                        decrementCount(con.AccountId);
                    } else if(trgOldMap.get(con.Id).AccountId != null) {
                        decrementCount(trgOldMap.get(con.Id).AccountId);
                    }
                }
            }
        }

        if(!accSizeSamplerCountMap.isEmpty()){
            List<Account> updAccs = [SELECT Id, Size__c, Assigned_Samplers_Count__c FROM Account WHERE Id IN :accSizeSamplerCountMap.keySet()];
            for(Account acc : updAccs){
                acc.Assigned_Samplers_Count__c = Integer.valueOf(accSizeSamplerCountMap.get(acc.Id).substringAfter('-'));
                if(acc.Size__c == null){
                    //If the size of Account is null, update according to current sampler count:
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
        String accSize;
        Integer recentCount;
        String sizeAndCount = accSizeSamplerCountMap.get(con.AccountId);
        if(sizeAndCount != null){
            accSize = sizeAndCount.substringBefore('-');
            recentCount = Integer.valueOf(sizeAndCount.substringAfter('-'));
        }
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
        if(currentCount > 0){
            currentCount--;
        }
        sizeAndCount = sizeAndCount.substringBefore('-') + '-' + currentCount;
        accSizeSamplerCountMap.put(accId, sizeAndCount);
    }
}
