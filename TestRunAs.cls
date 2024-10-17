@isTest
private class TestRunAs {
    public static testMethod void testRunAsStandard() {
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User stdUsr = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);

        System.runAs(stdUsr) {
            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            System.debug('Attempting to access EntityAPI_Country__mdt:');
            System.debug(LWCUtility.getCountriesFromMetadata());
            System.debug('----------');
        }
    }

    public static testMethod void testRunAsAdmin() {
        // Create a unique UserName
        String uniqueUserName = 'adminuser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE 'System Admin%'];
        User adminUsr = new User(Alias = 'admusr', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);

        System.runAs(adminUsr) {
            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            System.debug('Attempting to access EntityAPI_Country__mdt:');
            System.debug(LWCUtility.getCountriesFromMetadata());
            System.debug('----------');
        }
    }
}