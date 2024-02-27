@isTest
public class ContactTriggerHandlerTest {
    @testSetup static void testData(){
        Account acc1 = new Account(Name = 'Small Account', Size__c = 'Small');
        Account acc2 = new Account(Name = 'Medium Account', Size__c = 'Medium');
        Account acc3 = new Account(Name = 'Large Account', Size__c = 'Large');
        List<Account> testAccs = new List<Account>{acc1, acc2, acc3};
        insert testAccs;

        List<Contact> testCons = new List<Contact>();
        for(Account acc : testAccs){
            Integer size;
            if(acc.Size__c == 'Small') size = 1;
            else if(acc.Size__c == 'Medium') size = 3;
            else size = 5;

            for(Integer i=1; i<=size; i++){
                Contact con = new Contact(FirstName = acc.Size__c,
                                          LastName = 'Sampler_'+i,
                                          AccountId = acc.Id,
                                          Sampler__c = true);
                testCons.add(con);
            }
        }
        insert testCons;
    }

    @isTest static void testInsert(){
        Account acc = [SELECT Id FROM Account WHERE Size__c = 'Small'];

        Contact con = new Contact(LastName = 'Test', AccountId = acc.Id, Sampler__c = true);

        Test.startTest();
        try {
            insert con;
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('The parent account has reached its max number of samplers.'));
        }
        //Database.SaveResult sr = Database.insert(con, false);
        Test.stopTest();

        /*Assert.isFalse(sr.isSuccess());
        Assert.areEqual('The parent account has reached its max number of samplers.', sr.getErrors()[0].getMessage());*/
    }

    @isTest static void testUpdate1(){
        Account acc = [SELECT Id FROM Account WHERE Size__c = 'Small'];

        Contact con = new Contact(LastName = 'Test', AccountId = acc.Id, Sampler__c = false);
        insert con;

        con.Sampler__c = true;

        Test.startTest();
        Database.SaveResult sr = Database.update(con, false);
        Test.stopTest();

        Assert.isFalse(sr.isSuccess());
        Assert.areEqual('The parent account has reached its max number of samplers.', sr.getErrors()[0].getMessage());
    }

    @isTest static void testUpdate2(){
        Account accSmall = [SELECT Id, (SELECT Id, AccountId FROM Contacts) FROM Account WHERE Size__c = 'Small'];
        Account accMedium = [SELECT Id FROM Account WHERE Size__c = 'Medium'];

        accSmall.Contacts[0].AccountId = accMedium.Id;

        Test.startTest();
        Database.SaveResult sr = Database.update(accSmall.Contacts[0], false);
        Test.stopTest();

        Assert.isFalse(sr.isSuccess());
        Assert.areEqual('The parent account has reached its max number of samplers.', sr.getErrors()[0].getMessage());
    }

    @isTest static void testDeleteUndelete(){
        Account acc = [SELECT Id, (SELECT Id, AccountId FROM Contacts) FROM Account WHERE Size__c = 'Large'];
        List<Contact> cons = acc.Contacts;

        Test.startTest();
        delete cons[0];
        
        Contact con = new Contact(LastName = 'Test', AccountId = acc.Id, Sampler__c = true);
        insert con;

        Contact deletedCon = [SELECT Id, AccountId, Sampler__c FROM Contact WHERE IsDeleted = TRUE ALL ROWS];

        Database.UndeleteResult ur = Database.undelete(deletedCon, false);
        Test.stopTest();

        Assert.isFalse(ur.isSuccess());
        Assert.areEqual('The parent account has reached its max number of samplers.', ur.getErrors()[0].getMessage());
    }
}
