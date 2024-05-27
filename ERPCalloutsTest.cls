@isTest
public class ERPCalloutsTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account(Name = 'Test Acc',
                                  IlgarId__c = 'TESTCMPAKDC0A5',
                                  IFSId__c = '12012012',
                                  CIAID__c = '01HHQK1KAEWE6E5MV9984FTEST');
        insert acc;
    }

    @isTest static void testInsert(){
        ERPCalloutsMock mock = new ERPCalloutsMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Account testAcc = [SELECT Id FROM Account];
        Contract con = new Contract(AccountId = testAcc.Id,
                                    Status = 'Draft',
                                    StartDate = System.today(),
                                    ContractTerm = 1,
                                    ServiceType__c = 'Karayolu Taşımacılığı',
                                    Maturity__c = 10,
                                    DebitMemoMaturityDay__c = 20);
        
        Test.startTest();
        insert con;
        Test.stopTest();

        Assert.areEqual(1, mock.numCallouts);
    }

    @isTest static void testUpdate(){
        ERPCalloutsMock mock = new ERPCalloutsMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Account testAcc = [SELECT Id FROM Account];
        Contract con = new Contract(AccountId = testAcc.Id,
                                    Status = 'Draft',
                                    StartDate = System.today(),
                                    ContractTerm = 1,
                                    ServiceType__c = 'Karayolu Taşımacılığı',
                                    Maturity__c = 10,
                                    DebitMemoMaturityDay__c = 20);

        Test.startTest();
        insert con;
        con.Maturity__c = 15;
        con.DebitMemoMaturityDay__c = 25;
        con.Status = 'Activated';
        update con;
        Test.stopTest();

        Assert.areEqual(2, mock.numCallouts);
    }
}