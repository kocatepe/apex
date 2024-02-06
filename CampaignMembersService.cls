public with sharing class CampaignMembersService {

    public static void setIdentifiers(list<CampaignMember> members, System.TriggerOperation event) {
  
      if ( Utility.campaignMemberTriggerEnabled() ) {
  
        switch on event {
  
          when BEFORE_INSERT, BEFORE_UPDATE {
            for (CampaignMember member : members) {
              member.UniqueIdentifier__c = CampaignMembersService.getIdentifier(member);
            }
          }
  
          when AFTER_INSERT, AFTER_UPDATE {
            createMembersForPartners(members);
          }
        }
      }
    }

    public static String getIdentifier(CampaignMember member) {
  
      if (member.LeadId != null) {
        return String.valueOf(member.CampaignId) + String.valueOf(member.LeadId);
  
      } else if (member.AccountId != null) {
        return String.valueOf(member.CampaignId) + String.valueOf(member.AccountId);
  
      } else {
        return String.valueOf(member.CampaignId) + String.valueOf(member.ContactId);
  
      }
    }

    private static void createMembersForPartners(list < CampaignMember > members) {

      // Collect unique Account Id's and Event Id's
      set < String > campaignIds = new set < String >();
      set < String > accountIds = new set < String >();
  
      for (CampaignMember member : members) {
        campaignIds.add(member.CampaignId);
        accountIds.add(member.AccountId);
      }

      // Remove null values
      accountIds.remove(null);

      // Collect identifiers for already registered schools. We don't need duplicates.
      set < String > campaignSchoolKeys = new set < String >();
  
      for (CampaignMember member : [Select Id
                                   , CampaignId
                                   , AccountId
                                   From CampaignMember
                                   Where (CampaignId IN :campaignIds)
                                   And (AccountId != null)]) {
  
        campaignSchoolKeys.add( String.valueOf(member.CampaignId) + String.valueOf(member.AccountId) );
      }

      // Collect Relationships for all relevant Schools
      map<String, list<AccountRelation__c>> accountRelationsMap = new map<String, list<AccountRelation__c>>();
  
      for (AccountRelation__c accountRelation : [Select Id
                                                , RelatedTo__c
                                                , School__c
                                                , School__r.Name
                                                From AccountRelation__c
                                                Where (RelatedTo__c IN :accountIds)
                                                And (School__c != null)]) {
  
        list < AccountRelation__c > tempList = new list < AccountRelation__c >();
  
        if ( accountRelationsMap.containsKey(accountRelation.RelatedTo__c) ) {
          tempList = accountRelationsMap.get(accountRelation.RelatedTo__c);
        }
  
        tempList.add(accountRelation);
        accountRelationsMap.put(accountRelation.RelatedTo__c, tempList);
      }

      // Initialize list for Attendees to be created
      list < CampaignMember > newMembers = new list < CampaignMember >();

      // Loop through the triggered attendees
      for (CampaignMember member : members) {
        // Only continue if an Account is involved
        // and if that Account has at least one (partnership) relation
        if ( member.AccountId != null
             && accountRelationsMap.containsKey(member.AccountId) ) {
  
          for ( AccountRelation__c accountRelation : accountRelationsMap.get(member.AccountId) ) {
  
            // Create unique key for this Event/Account combination
            String key = String.valueOf(member.CampaignId) + String.valueOf(accountRelation.School__c);

            // Only continue if we don't know this key yet
            if (campaignSchoolKeys.contains(key) == false) {

              CampaignMember newMember = new CampaignMember();
              newMember.CampaignId = member.CampaignId;
              newMember.AccountId = accountRelation.School__c;
              // newMember.conference360__Account_Name__c = accountRelation.School__r.Name;
              // newMember.SourceAttendee__c = member.Id;
  
              // Add the member to the list
              newMembers.add(newMember);
  
              // Add the key so that we don't create this record again
              campaignSchoolKeys.add(key);
            }
          }
        }
      }

      // Make sure we don't keep doing this
      Utility.disableCampaignMemberTrigger();
  
      // Insert the new attendees
      insert newMembers;
    }
}