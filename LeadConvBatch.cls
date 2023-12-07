public class LeadConvBatch implements Database.Batchable<SObject>, Database.Stateful {
    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
    Database.LeadConvertResult[] leadConvertResults;

    public Database.QueryLocator start(Database.BatchableContext bc){
        Database.QueryLocator ql = Database.getQueryLocator([
                                SELECT Id, Ready_to_Convert__c, Email, Company, AnnualRevenue, IsConverted
                                FROM Lead WHERE (Ready_to_Convert__c = TRUE) AND (IsConverted = FALSE)]);
        return ql;
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        Set<String> emails = new Set<String>();
        Set<String> companies = new Set<String>();
        for(Lead ld : scope){
            if(ld.Email != null){
                emails.add(ld.Email);
            }
            companies.add(ld.Company);
        }

        List<Contact> matchCon = [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :emails];
        Map<String,Contact> conMap = new Map<String,Contact>();
        for(Contact c : matchCon){
            conMap.put(c.Email, c);
        }
        List<Account> matchAcc = [SELECT Id, Name FROM Account WHERE Name IN :companies];
        Map<String,Account> accMap = new Map<String,Account>();
        for(Account a : matchAcc){
            accMap.put(a.Name, a);
        }

        List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();
        for(Lead ld : scope){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(ld.Id);

            if(conMap.keySet().contains(ld.Email)){
                lc.setContactId(conMap.get(ld.Email).Id);
                lc.setAccountId(conMap.get(ld.Email).AccountId);
                lc.setDoNotCreateOpportunity(true);
            } else if(accMap.keySet().contains(ld.Company)){
                lc.setAccountId(accMap.get(ld.Company).Id);
                if(ld.AnnualRevenue <= 250000){
                    lc.setDoNotCreateOpportunity(true);
                }
            }

            lc.setConvertedStatus(convertStatus.MasterLabel);
            lcs.add(lc);
        }

        if(!lcs.isEmpty()){
            leadConvertResults.addAll(Database.convertLead(lcs, false));
        }
    }

    public void finish(Database.BatchableContext bc) {
        for(Database.LeadConvertResult res : leadConvertResults){
            if(!res.isSuccess()){
                System.debug('ERROR: ' + res.getErrors().get(0).getStatusCode() + ':');
                System.debug(res.getErrors().get(0).getMessage());
                System.debug('--------------------------------------------------');
            }
        }
    }

    public String schedNightly(){
        String crone = '0 0 0 * * ?';
        return System.schedule('Convert Leads', crone, new LeadConvScheduler());
    }

    private class LeadConvScheduler implements Schedulable {
        public void execute(SchedulableContext sc){
            Database.executeBatch(new LeadConvBatch());
        }
    }
}