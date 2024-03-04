public with sharing class DelegateGroupTooling {
    @InvocableMethod(label='Get Delegated Group Member User Ids' description='Returns the list of member user ids for a given Delegated Group Developer Name')
    public static List<Id> getMemberUserIds(List<String> delegateGroupName){
        //1. Use delegateGroupName in a Tooling API query to retrieve DelegateGroupId
        String queryDelegateGroup = 'SELECT Id, DeveloperName FROM DelegateGroup WHERE DeveloperName = \'' + delegateGroupName[0] + '\' LIMIT 1';
        List<Object> groupRecords = toolingQuery(queryDelegateGroup);
        Map<String, Object> groupData = (Map<String, Object>) groupRecords[0];
        Id delegateGroupId = (Id)groupData.get('Id');

        //2. Use delegateGroupId in a Tooling API query to retrieve userIds
        String queryDelegateGroupMember = 'SELECT DelegateGroupId, UserOrGroupId FROM DelegateGroupMember WHERE DelegateGroupId = \'' + delegateGroupId + '\'';
        List<Object> userRecords = toolingQuery(queryDelegateGroupMember);

        List<Id> userIds = new List<Id>();
        for(Object rec : userRecords){
            Map<String, Object> userData = (Map<String, Object>) rec;
            userIds.add((Id) userData.get('UserOrGroupId'));
        }
        return userIds;
    }

    private static List<Object> toolingQuery(String query){
        String endpoint = '/services/data/v58.0/tooling/query/?q=';
        String urlString = URL.getOrgDomainURL().toExternalForm() + endpoint + EncodingUtil.urlEncode(query, 'UTF-8');

        HttpRequest request = new HttpRequest();
        request.setEndpoint(urlString);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        Http http = new Http();
        HttpResponse response = http.send(request);

        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return (List<Object>) jsonResponse.get('records');
    }
}