public class DelegateGroupTooling {
    static Profile sysAdmin = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    static Set<String> admins = new Set<String>();
    static {
        for (User u : [SELECT Id, ProfileId FROM User WHERE ProfileId = :sysAdmin.Id]) {
            admins.add(u.Id);
        }
        System.debug(admins);
    }
    static CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='New_Notification'];
    
    @future(callout=true)
    public static void findMemberUsersAndNotifyAdmins(String delegateGroupName, Set<Id> userIds){
        //1. Use delegateGroupName in a Tooling API query to retrieve delegateGroupId
        String queryDelegateGroup = 'SELECT Id, DeveloperName FROM DelegateGroup WHERE DeveloperName = \'' + delegateGroupName + '\' LIMIT 1';
        List<Object> groupRecords = toolingQuery(queryDelegateGroup);
        
        Map<String, Object> groupData = (Map<String, Object>) groupRecords[0];
        Id delegateGroupId = (Id) groupData.get('Id');

        //2. Use delegateGroupId in a Tooling API query to retrieve memberIds
        String queryDelegateGroupMember = 'SELECT DelegateGroupId, UserOrGroupId FROM DelegateGroupMember WHERE DelegateGroupId = \'' + delegateGroupId + '\'';
        List<Object> userRecords = toolingQuery(queryDelegateGroupMember);

        List<Id> memberIds = new List<Id>();
        for(Object rec : userRecords){
            Map<String, Object> userData = (Map<String, Object>) rec;
            memberIds.add((Id) userData.get('UserOrGroupId'));
        }

        for(User u : [SELECT Id, CreatedById FROM User WHERE Id IN :userIds]){
            if(memberIds.contains(u.CreatedById)){
                notifyAdmins(u.Id);
            }
        }
    }
    
    private static List<Object> toolingQuery(String query){
        String urlMidString = '/services/data/v63.0/tooling/query/?q=';
        String endpoint = URL.getOrgDomainURL().toExternalForm() + urlMidString + EncodingUtil.urlEncode(query, 'UTF-8');
        string userSessionId = UserInfo.getOrganizationId() + '' + UserInfo.getSessionId().substring(15);
        
        HTTP http = new HTTP();
        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + userSessionId);
        HTTPResponse res = http.send(req);

        if(res.getStatusCode() == 200){
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug((List<Object>) jsonResponse.get('records'));
            return (List<Object>) jsonResponse.get('records');
        } else {
            System.debug(res);
            return null;
        }
    }

    @testVisible
    private static void notifyAdmins(Id newUserId){
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('A New User is Created');
        notification.setBody('One of the Delegated Admins has created a new user record.');
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(newUserId);
        notification.send(admins);

        System.debug('All notifications must have been sent now...');
    }
}
