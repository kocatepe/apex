@isTest
public with sharing class DelegateGroupToolingTest {
    @isTest static void test(){
        List<User> usersBefore = [SELECT Id FROM User];

        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User uTest = new User();
        uTest.Username = 'testUser@hu.nl';
        uTest.Alias = 'uTest';
        uTest.LastName = 'Testing';
        uTest.Email = 'fake@email.xyz';
        uTest.TimeZoneSidKey = 'America/Los_Angeles';
        uTest.LocaleSidKey = 'en_US';
        uTest.EmailEncodingKey = 'UTF-8';
        uTest.ProfileId = p.Id;
        uTest.LanguageLocaleKey = 'en_US';

        Test.setMock(HttpCalloutMock.class, new ToolingCalloutMock());

        Test.startTest();
        insert uTest;
        DelegateGroupTooling.notifyAdmins(uTest.Id);
        Test.stopTest();

        List<User> usersAfter = [SELECT Id FROM User];
        Assert.areEqual((usersBefore.size()+1), usersAfter.size());
    }
}