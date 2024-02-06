public with sharing class AfterEventEmailScheduler {

    private void log(String t) {
        System.debug('#### [Scheduler] - ' + t);
    }

    // Id's of the Events which are actually retrieved from database
    set < Id > actualEventIds;

    // Id's as provided by the invoking class. Can be either event or setting Id's
    set < Id > eventOrSettingIds;

    // Indicates whether or not Jobs will be rescheduled
    Boolean abortWithoutReschedule;

    // Holds the events which are actually retrieved from database
    list < conference360__Event__c > events;

    // Holds the events which need to be updated
    list < conference360__Event__c > events2Update;

    // Schedules to be inserted. A custom object is used to avoid scheduled Jobs limit
    list < AfterEventEmailSchedule__c > schedules;

    // Schedules to be deleted
    list < AfterEventEmailSchedule__c > schedules2Delete;

    public AfterEventEmailScheduler(set < Id > eventOrSettingIds) {
        this.abortWithoutReschedule = false;
        this.eventOrSettingIds = eventOrSettingIds;
        this.actualEventIds = new set < Id >();
        this.events2Update = new list < conference360__Event__c >();
        this.schedules = new list < AfterEventEmailSchedule__c >();
        this.schedules2Delete = new list < AfterEventEmailSchedule__c >();
    }

    //Aborts scheduled jobs
    //Deletes AfterEventEmailSchedule__c records (with save())
    //Nullifies if: event.AfterEventEmailSchedule__c >= System.today()
    public void abortJobSchedules() {
        this.abortWithoutReschedule = true;
        this.getEvents(); //119
        this.abortJobs(); //140
        this.save(); //203
    }

    public void rebuildJobSchedules() {
        this.getEvents(); //119
        this.abortJobs(); //140

        for (conference360__Event__c event :this.events) {

            this.log('Event: ' + event);

            if (event.conference360__Status__c != CommonConstants.EVENT_STATUS_ACTIVE) {
                this.log('Event not Active');
                this.nullifyScheduledDate(event, false);
                continue;
            }

            if (event.conference360__Event_Settings__c == null) {
                this.log('No Settings present');
                this.nullifyScheduledDate(event, false);
                continue;
            }

            if (event.conference360__Event_Settings__r.SendAfterEventEmail__c == false) {
                this.log ('Sending Thank You Email set to FALSE');
                this.nullifyScheduledDate(event, false);
                continue;
            }

            if ( event.conference360__Event_End_Date__c < System.today() ) {
                this.log ('Event has already taken place');
                this.nullifyScheduledDate(event, true);
                continue;
            }

            this.log ('Settings present');
            this.log ('Sending Thank You Email set to true');
            this.log ('Is future event');

            Integer hours = 0;
            if (event.conference360__Event_Settings__r.AfterEventEmailHours__c != null) {
                hours = Integer.valueOf(event.conference360__Event_Settings__r.AfterEventEmailHours__c);
            }

            DateTime nextRun = AfterEventEmailUtils.getDate(event);
            nextRun = nextRun.addHours(hours);
            this.log('Next run: ' + nextRun + ' (NOW: ' + System.now() + ')');

            if ( nextRun <= System.now() ) {
                this.log('Next run cannot be in the past');
                this.nullifyScheduledDate(event, true);
                continue;
            }

            this.scheduleJob(event, nextRun); //158
            this.log('Job is scheduled');

            if (event.AfterEventEmailSchedule__c != nextRun) {
                event.AfterEventEmailSchedule__c = nextRun;
                this.events2Update.add(event);
            }
        }

        this.save(); //203
    }

    // Clear schedule time if necessary
    private void nullifyScheduledDate(conference360__Event__c event, Boolean futureDateOnly) {
        if ( event.AfterEventEmailSchedule__c != null && ( futureDateOnly == false || event.AfterEventEmailSchedule__c >= System.today() ) ) {
            event.AfterEventEmailSchedule__c = null;
            this.events2Update.add(event);
        }
    }

    // Get actual events, based on provided Id's
    private void getEvents() {
        this.events = new List < conference360__Event__c >();
        for (conference360__Event__c e :[Select Id
                                       , Name
                                       , Format__c
                                       , AfterEventEmailSchedule__c
                                       , conference360__Status__c
                                       , conference360__Event_End_Date__c
                                       , conference360__Event_End_Time__c
                                       , conference360__Event_Settings__c
                                       , conference360__Event_Settings__r.SendAfterEventEmail__c
                                       , conference360__Event_Settings__r.AfterEventEmailHours__c
                                       From conference360__Event__c
                                       Where (Id IN :this.eventOrSettingIds)
                                       Or (conference360__Event_Settings__c IN :this.eventOrSettingIds)]) {
        this.events.add(e);
        this.actualEventIds.add(e.Id);
        }
    }

    // Abort (scheduled) Jobs
    private void abortJobs() {
        // Abort scheduled jobs
        for (CronTrigger cronTrigger :[Select Id, CronJobDetail.Name From CronTrigger Where CronJobDetail.Name = :this.getJobNames()]) {
            this.log('Aborting Job: ' + cronTrigger.Id + ' (' + cronTrigger.CronJobDetail.Name + ')');
            System.abortJob(cronTrigger.Id);
        }

        // Delete schedules
        this.schedules2Delete = [Select Id From AfterEventEmailSchedule__c Where EventId__c IN :this.actualEventIds];

        // If no new schedules are to be created,
        // then we need to nullify the AfterEventEmailSchedule__c field
        if (this.abortWithoutReschedule) {
            this.nullifyScheduledDates(true); //193
        }
    }

    // Schedule Jobs -- called from 98 (rebuildJobSchedules) -- scheduleJob(event, nextRun);
    private void scheduleJob(conference360__Event__c event, DateTime runTime) {
        // If Job is scheduled for today, then schedule it immediately.
        // Otherwise save it in the After Event Email schedule object
        if ( runTime.date() == System.today() ) {
            // Job will be running today
            System.schedule( this.getJobName(event), this.getCron(runTime), new AfterEventEmailSchedulable(event.Id) );
        } else {
            // Job will be running somewhere in the future
            this.schedules.add( new AfterEventEmailSchedule__c( Name = this.getJobName(event)
                                                              , EventId__c = event.Id
                                                              , Event__c = event.Id
                                                              , NextFireTime__c = runTime
                                                              , NextFireDate__c = runTime.date()
                                                              , Cron__c = getCron(runTime) ) );
        }
    }

    // Get the names of all events
    private set < String > getJobNames() {
        set < String > output = new set < String >();
        for (conference360__Event__c event :this.events) {
            output.add( this.getJobName(event) );
        }

        return output;
    }

    // Returns the Job Name to be used
    private String getJobName(conference360__Event__c event) {
        String jobName = AfterEventEmailUtils.JOB_NAME_PREFIX + event.Id;
        this.log('jobName: ' + jobName);
        return jobName;
    }

    // Nullifies the AfterEventEmailSchedule__c field for all events
    private void nullifyScheduledDates(Boolean futureOnly) {
        for (conference360__Event__c event :this.events) {
            this.nullifyScheduledDate(event, futureOnly);
        }
    }

    private String getCron(DateTime dt) {
        return dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
    }

    private void save() {  
        if (this.schedules2Delete != null && this.schedules2Delete.size() > 0) {
            delete this.schedules2Delete;
        }

        if (this.schedules != null && this.schedules.size() > 0) {
            upsert this.schedules EventId__c;
        }

        if (this.events2Update.size() > 0) {
            update this.events2Update;
        }
    }
}