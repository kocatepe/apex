@isTest
private class CampaignMembersServiceTest {
    @testSetup
    static void setup() {
        Campaign testCampaign = new Campaign(Name='Test Campaign');
        insert testCampaign;

        Lead testLead = new Lead(LastName='Test Lead', Company='Test Company');
        insert testLead;

        Account partner = new Account(Name = 'Test Account', Type = 'Partner');
        Account school = new Account(Name = 'Test School', Type = 'School');
        List<Account> accs = new List<Account>{partner, school};
        insert accs;

        Contact testContact = new Contact(LastName='Test Contact');
        insert testContact;

        AccountRelation__c partnership = new AccountRelation__c(RelatedTo__c = partner.Id, School__c = school.Id, RelationType__c = 'Partnership');
        insert partnership;
    }

    @isTest
    static void test() {
        //Query the parents.
        Campaign cam = [SELECT Id FROM Campaign LIMIT 1];
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        CampaignMember cmForLead = new CampaignMember(CampaignId = cam.Id, LeadId = ld.Id);
        CampaignMember cmForAccount = new CampaignMember(CampaignId = cam.Id, AccountId = acc.Id);
        CampaignMember cmForContact = new CampaignMember(CampaignId = cam.Id, ContactId = con.Id);

        List<CampaignMember> members = new List<CampaignMember>{cmForLead, cmForAccount, cmForContact};

        Test.startTest();
        insert members;
        Test.stopTest();

        List<CampaignMember> membersNow = [SELECT CampaignId, LeadId, AccountId, ContactId, UniqueIdentifier__c FROM CampaignMember];

        //Check if identifiers are created in the BEFORE event.
        for (CampaignMember member : membersNow) {
            if (member.LeadId != null) {
                Assert.areEqual((String.valueOf(member.CampaignId) + String.valueOf(member.LeadId)), member.UniqueIdentifier__c);
            } else if (member.AccountId != null) {
                //Assert.areEqual((String.valueOf(member.CampaignId) + String.valueOf(member.AccountId)), member.UniqueIdentifier__c);
            } else {
                Assert.areEqual((String.valueOf(member.CampaignId) + String.valueOf(member.ContactId)), member.UniqueIdentifier__c);
            }
        }

        //Check if members are created for partners in the AFTER event.
        List<AccountRelation__c> partnerships = [SELECT Id, RelationType__c FROM AccountRelation__c];
        //3 + 1 = 4
        Assert.areEqual((members.size() + partnerships.size()), membersNow.size());
    }
}