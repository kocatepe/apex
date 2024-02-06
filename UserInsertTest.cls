@isTest
public class UserInsertTest {
    @isTest static void getUsers(){
        List<User> users = [SELECT Id, Username, Alias, ProfileId, UserType, IndividualId FROM User];
        for (User u : users) {
            System.debug(u);
        }
        System.debug('Before insert: ' + users.size());

        User uTest = new User();
        uTest.Username = 'test@ede.lim';
        uTest.Alias = 'uTest';
        uTest.LastName = 'Chatester';
        uTest.Email = 'fake@email.yok';
        uTest.TimeZoneSidKey = 'Europe/Istanbul';
        uTest.LocaleSidKey = 'tr_TR';
        uTest.EmailEncodingKey = 'UTF-8';
        uTest.ProfileId = '00e8e000001QloyAAC';
        uTest.LanguageLocaleKey = 'en_US';

        insert uTest;
        System.debug(uTest);
        List<User> usersAfter = [SELECT Id FROM User];
        System.debug('After insert: ' + usersAfter.size());
    }
}