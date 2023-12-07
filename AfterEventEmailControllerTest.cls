@isTest
public with sharing class AfterEventEmailControllerTest {
    @TestSetup
    static void makeData(){
        List<conference360__Event_Settings__c> settings = new List<conference360__Event_Settings__c>();

        conference360__Event_Settings__c settingE = new conference360__Event_Settings__c();
        settingE.Name = 'Test Setting Evens';
        settingE.SendAfterEventEmail__c = true;
        SettingE.SendAfterEventEmailTo__c = 'Registered';
        settingE.AfterEventEmailHours__c = 2;
        settings.add(settingE);

        conference360__Event_Settings__c settingO = new conference360__Event_Settings__c();
        settingO.Name = 'Test Setting Odds';
        settingO.SendAfterEventEmail__c = false;
        settingO.AfterEventEmailHours__c = 3;
        settings.add(settingO);

        insert settings;

        conference360__Form__c form = new conference360__Form__c();
        form.Name = 'Test Form';
        insert form;

        Campaign campaign = new Campaign();
        campaign.Name = 'Test Campaign';
        insert campaign;

        List<conference360__Event__c> events = new List<conference360__Event__c>();
        for (Integer i = 0; i < 2; i++) {
            conference360__Event__c event = new conference360__Event__c();
            event.Name = 'Test Event ' + i;
            event.conference360__Event_Settings__c = settings[Math.Mod(i,2)].Id;
            event.conference360__Campaign__c = campaign.Id;
            event.conference360__Form2__c = form.Id;
            event.Format__c = 'Online';
            event.conference360__Time_Zone__c = '(GMT-05:00) Eastern Standard Time (America/New_York)';
            event.AfterEventEmailSchedule__c = System.now().addDays(i+1);
            event.conference360__Status__c = 'Active';
            event.conference360__Event_Start_Date__c = System.today().addDays(i+1);
            event.conference360__Event_Start_Time__c = System.now().time().addHours(i+1);
            event.conference360__Event_End_Date__c = event.conference360__Event_Start_Date__c;
            event.conference360__Event_End_Time__c = event.conference360__Event_Start_Time__c.addHours(1);
            event.conference360__Attendee_Limit__c = 100;
            events.add(event);
        }
        insert events;
    }

    //Testing EventTrigger: AFTER_INSERT
    @isTest static void testNewEvents(){
        List<conference360__Event__c> events = new List<conference360__Event__c>();
        Campaign campaign = [SELECT Id FROM Campaign LIMIT 1];
        conference360__Form__c form = [SELECT Id FROM conference360__Form__c];

        conference360__Event_Settings__c setting = [SELECT Id, SendAfterEventEmail__c FROM conference360__Event_Settings__c WHERE SendAfterEventEmail__c = true LIMIT 1];

        for (Integer i = 0; i < 7; i++) {
            conference360__Event__c event = new conference360__Event__c();
            event.Name = 'Insert Test Event ' + i;
            event.conference360__Event_Settings__c = setting.Id; //true, hours=2
            event.conference360__Campaign__c = campaign.Id;
            event.conference360__Form2__c = form.Id;
            event.Format__c = 'Online';
            event.conference360__Time_Zone__c = '(GMT-05:00) Eastern Standard Time (America/New_York)';
            event.AfterEventEmailSchedule__c = System.now().addDays(i);
            event.conference360__Status__c = 'Active';
            event.conference360__Event_Start_Date__c = System.today();
            event.conference360__Event_Start_Time__c = System.now().time().addHours(1);
            event.conference360__Event_End_Date__c = event.conference360__Event_Start_Date__c;
            event.conference360__Event_End_Time__c = event.conference360__Event_Start_Time__c.addHours(1);
            event.conference360__Attendee_Limit__c = 100;

            switch on i {
                when 1 {
                    event.conference360__Status__c = 'Draft';
                }
                when 2 {
                    event.conference360__Event_Settings__c = null;
                }
                when 3 {
                    conference360__Event_Settings__c setNoAfterEmail = [SELECT Id, SendAfterEventEmail__c FROM conference360__Event_Settings__c WHERE SendAfterEventEmail__c = false LIMIT 1];
                    event.conference360__Event_Settings__c = setNoAfterEmail.Id;
                }
                when 4 {
                    event.conference360__Event_Start_Date__c = System.today().addDays(-1);
                    event.conference360__Event_End_Date__c = System.today().addDays(-1);
                }
                when 5 {
                    //nextRun <= System.now()
                    event.conference360__Event_Start_Time__c = System.now().time().addHours(-5);
                    event.conference360__Event_End_Time__c = System.now().time().addHours(-4);
                }
                when 6 {
                    //Will be scheduled tomorrow
                    event.conference360__Event_End_Date__c = System.today().addDays(1);
                }
            }

            events.add(event);
        }

        List<CronTrigger> cronBeforeInsert = [Select Id From CronTrigger];
        List<AfterEventEmailSchedule__c> scheduleBeforeInsert = [SELECT NextFireDate__c FROM AfterEventEmailSchedule__c WHERE NextFireDate__c = :System.today().addDays(1)];

        Test.startTest();
        insert events;
        Test.stopTest();

        List<CronTrigger> cronAfterInsert = [Select Id From CronTrigger];
        List<AfterEventEmailSchedule__c> scheduleAfterInsert = [SELECT NextFireDate__c FROM AfterEventEmailSchedule__c WHERE NextFireDate__c = :System.today().addDays(1)];

        //Only 1 event got scheduled
        Assert.areEqual(1, (cronAfterInsert.size()-cronBeforeInsert.size()));
        //1 more event will be scheduled tomorrow
        Assert.areEqual(1, (scheduleAfterInsert.size()-scheduleBeforeInsert.size()));
    }

    //Testing EventTrigger: AFTER_UPDATE
    @isTest static void testUpdatedEvents(){
        conference360__Event__c eventBeforeUpdate = [SELECT Id, AfterEventEmailSchedule__c FROM conference360__Event__c LIMIT 1];
        String eventId = eventBeforeUpdate.Id;

        eventBeforeUpdate.conference360__Status__c = 'Canceled';

        Test.startTest();
        update eventBeforeUpdate;
        Test.stopTest();

        conference360__Event__c eventAfterUpdate = [SELECT Id, AfterEventEmailSchedule__c FROM conference360__Event__c WHERE Id = :eventId];

        //AfterEventEmailSchedule__c field is nullified
        Assert.isNotNull(eventBeforeUpdate.AfterEventEmailSchedule__c);
        Assert.isNull(eventAfterUpdate.AfterEventEmailSchedule__c);
    }

    //Testing EventTrigger: BEFORE_DELETE
    @isTest static void testDeletedEvents(){
        conference360__Event__c event = [SELECT Id FROM conference360__Event__c LIMIT 1];

        Test.startTest();
        delete event;
        Test.stopTest();

        List<conference360__Event__c> eventAfterDelete = [SELECT Id FROM conference360__Event__c WHERE Id = :event.Id];

        Assert.isNotNull(event);
        Assert.areEqual(0, eventAfterDelete.size());
    }

    //Testing EventSettingsTrigger: AFTER_UPDATE
    @isTest static void testUpdatedEventSettings(){
        conference360__Event_Settings__c setting = [SELECT Id, SendAfterEventEmail__c FROM conference360__Event_Settings__c WHERE SendAfterEventEmail__c = true LIMIT 1];
        String settingId = setting.Id;

        conference360__Event__c eventBeforeUpdate = [SELECT Id, AfterEventEmailSchedule__c, conference360__Event_Settings__c FROM conference360__Event__c WHERE conference360__Event_Settings__c = :settingId LIMIT 1];
        String eventId = eventBeforeUpdate.Id;

        setting.SendAfterEventEmail__c = false;

        Test.startTest();
        update setting;
        Test.stopTest();

        conference360__Event__c eventAfterUpdate = [SELECT Id, AfterEventEmailSchedule__c FROM conference360__Event__c WHERE Id = :eventId];

        //AfterEventEmailSchedule__c field is nullified
        Assert.isNotNull(eventBeforeUpdate.AfterEventEmailSchedule__c);
        Assert.isNull(eventAfterUpdate.AfterEventEmailSchedule__c);
    }
}